---
layout: post
title:  "From zero to embedded post-quantum TLS: part 2"
date: 2025-04-27 11:37:56 -0400
categories: cryptography
---

Part 1 left off with a firmware that flashes the on board LED. In this part, we will connect the Pico 2 W to some Wifi network and work with two UDP-based protocols: DNS and NTP.

But first, it would be very helpful to have a way to communicate other than a single LED light. One way is to set up standard IO over USB, which is already enabled in the CMakeLists.txt file using the function `pico_enable_stdio_usb(<target> 1)`. In the main program, you will need to initialize `stdio` using `stdio_init_all()` from `pico_stdlib`, then can use `printf` and its siblings to print to USB. `minicom` can be used to read the serial input, although I find its key bindings annoying to work with, so I asked ChatGPT to write me a Python script to do the exact same thing:

```python
#!/usr/bin/env python3

import sys
import serial
import argparse

def read_serial(port, baudrate, log_file=None):
    try:
        # Open serial port
        ser = serial.Serial(port, baudrate=baudrate, timeout=1)
        print(f"Reading from {port} at {baudrate} baud...")
        
        # Open log file if specified
        log = open(log_file, "a") if log_file else None

        while True:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if line:
                print(line)  # Print to stdout
                if log:
                    log.write(line + "\n")  # Write to log file
                    log.flush()
    except serial.SerialException as e:
        print(f"Error: {e}")
    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
        if log:
            log.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Read from a serial port and output to stdout (and optional log file).")
    parser.add_argument("port", help="Serial port (e.g., /dev/ttyUSB0, COM3)")
    parser.add_argument("-b", "--baudrate", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("-C", "--logfile", help="Log file to write output to")

    args = parser.parse_args()
    read_serial(args.port, args.baudrate, args.logfile)
```

On MacOS, the USB serial console usually shows up under `/dev/tty.usbmodemXXX`.

# Connecting to Wifi
Connecting to Wifi requires the Wifi driver and a network library. Pico SDK bundled `cyw43` (wireless chip driver) and `lwip` together, which can be easily linked against in the CMakeLists.txxt file.

```cmake
add_executable(part2 src/part2.c)
pico_enable_stdio_uart(part2 0)
pico_enable_stdio_usb(part2 1)
target_link_libraries(part2 pico_stdlib pico_cyw43_arch_lwip_poll)
pico_add_extra_outputs(part2)
```

In this series I want to avoid the complexity of asynchronous programs, so I will stick with `pico_cyw43_arch_lwip_poll` instead of other architectures such as `pico_cyw43_arch_lwip_thread_safe_background`.

`lwip` is a [lightweight IP stack](https://www.nongnu.org/lwip/2_1_x/index.html). Pico SDK already implemented the network interface parts so we don't need to worry about it in this series. We do need to provide a configuration header file `lwip_opts.h`. A good starting point can be found [here](https://raw.githubusercontent.com/raspberrypi/pico-examples/refs/heads/master/pico_w/wifi/lwipopts_examples_common.h). It should be placed under `config/lwipopts.h`, which should already be among the include directories as part 1 sets up the CMakeLists.txt file.

Like `stdio`, the Wifi driver must first be initialize with `cyw43_arch_init()`. We will be connecting to an existing Wifi network (which is called "station mode", which is in contrast with "access point mode", meaning we are hosting a Wifi netowkr), so `cyw43_arch_enable_sta_mode()` should be called after initialization.

Connecting to a Wifi network is as easy as calling `cyw43_arch_wifi_connect_blocking(ssid, password, auth)`, which will block until joining a network or encountering an error. Another helpful function is `cyw43_wifi_link_status`, which returns the status of the link. I combined these functions into a single helper function that can repeatedly attempt to connect until success:

```c
// src/part2.c
#include <pico/cyw43_arch.h>
#include <pico/stdio.h>

static bool wifi_connected() {
  int status = cyw43_wifi_link_status(&cyw43_state, CYW43_ITF_STA);
  return (status == CYW43_LINK_UP) || (status == CYW43_LINK_JOIN);
}

void ensure_wifi_connection_blocking(const char *ssid, const char *pw,
                                     uint32_t auth) {
  while (!wifi_connected()) {
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0);

    if (cyw43_arch_wifi_connect_blocking(ssid, pw, auth) != 0) {
      // print some debug information about failure
    }
  }
  // Turn on LED to indicate Wifi is up
  cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1);
}

int main(void) {
  stdio_init_all();
  if (cyw43_arch_init()) {
    printf("CYW43 failed to initialize\n");
    return -1;
  }
  cyw43_arch_enable_sta_mode();
  ensure_wifi_connection_blocking(WIFI_SSID, WIFI_PASSWORD,
                                  CYW43_AUTH_WPA2_AES_PSK);

  while (1) {
    sleep_ms(1000);
  }
}
```

The credentials to your local Wifi network can be sensitive, so it is important to never hardcode them into source code. For local development purposes, it is sufficient to store them as environment variables, then pass them into the compiler as macros:

```cmake
set(WIFI_SSID $ENV{WIFI_SSID})
set(WIFI_PASSWORD $ENV{WIFI_PASSWORD})
target_compile_definitions(part2 PRIVATE
    WIFI_SSID=\"${WIFI_SSID}\"
    WIFI_PASSWORD=\"${WIFI_PASSWORD}\"
)
```

# Domain Name Service (DNS)
We need DNS to resolve hostname such as `github.com` to IP addresses (for simplicity I will stick with IPv4 address). Fortunately, much of DNS is abstracted away by lwip and I don't need to interact with the underlying UDP control block.

I will mainly work with the `dns_gethostbyname` function in `lwip/dns.h`. According to the [documentation](https://www.nongnu.org/lwip/2_0_x/group__dns.html), I need to handle two scenarios:

- The function returns `ERR_OK`, in which case I have an `ip_addr_t` that is ready to go
- The function returns `ERR_INPROGRESS`, in which case I need to wait for the callback to resolve the DNS query

My solution is with a struct that includes flags that can be used to indicate various status:

```c
#include <lwip/dns.h>
#include <lwip/ip_addr.h>

typedef struct dns_result {
  ip_addr_t addr;
  // remote hostname has been successfully found, addr can be used
  bool resolved;
  // DNS resolution is complete
  bool complete;
} dns_result_t;

static void dns_handler(const char *name, const ip_addr_t *ipaddr, void *arg) {
  dns_result_t *dns_res = (dns_result_t *)arg;
  if (ipaddr) {
    dns_res->addr = *ipaddr;
    dns_res->resolved = true;
  } else {
    dns_res->resolved = false;
  }
  dns_res->complete = true;
}

void dns_result_init(dns_result_t *res) {
  ip_addr_set_zero(&res->addr);
  res->resolved = false;
  res->complete = false;
}

/**
 * Block until callback is called. Check dns_res->resolved for success or not
 */
void dns_gethostbyname_blocking(const char *hostname, dns_result_t *dns_res) {
  err_t err = dns_gethostbyname(hostname, &dns_res->addr, dns_handler, dns_res);
  if (err == ERR_OK) {
    // DNS record has been cached, no need to check callback
    dns_res->complete = true;
    dns_res->resolved = true;
    return;
  } else if (err == ERR_INPROGRESS) {
    // Wait for callback
    while (!dns_res->complete) {
      cyw43_arch_poll();
    }
  } else {
    exit(-1);
  }
}
```

We can test this DNS implementation against some publicly known domain name, such as `github.com`:

```c
#define PEER_HOSTNAME "api.github.com"

dns_result_t dns;
dns_result_init(&dns);
dns_gethostbyname_blocking(PEER_HOSTNAME, &dns);
if (dns.resolved) {
    printf("%s resolved to %s\n", PEER_HOSTNAME, ipaddr_ntoa(&dns.addr));
}
```

# Network Time Protocol (NTP)
Later on we will need to verify the validity of X509 certificates, for which we will need to know the current time. The Pico has a high-fidelity timer, so we just need to sync the clock once. The network time protocol (NTP) is built on top of NTP, which can be used to ask some network server "what time is it":

```c
#define NTP_TIMEOUT_MS (10 * 1000)
#define NTP_DELTA_SECONDS 2208988800 // seconds between 1900 and 1970
#define NTP_HOSTNAME "pool.ntp.org"
#define NTP_PORT 123
#define NTP_MSG_LEN 48
#define NTP_STRATUM_INVALID 0
#define NTP_MODE_SERVER 4
#define NTP_MODE_CLIENT 0b00000011
#define NTP_MODE_MASK 0x7
#define NTP_LI_NO_WARNING 0
#define NTP_VN_VERSION_3 0b00011000

typedef struct ntp_client {
  ip_addr_t ntp_ipaddr;
  uint16_t ntp_port;
  struct udp_pcb *pcb;
  // whether NTP response has been processed
  bool processed;
  // indicate the status of the NTP sync
  err_t ntp_err;
  // The UNIX timestamp (seconds since 1970) received from NTP
  time_t epoch;
  // The output of get_absolute_time the moment when NTP response is processed
  absolute_time_t abs_time_at_ntp_resp;
} ntp_client_t;

static void ntp_resp_handler(void *arg, struct udp_pcb *pcb, struct pbuf *p,
                             const ip_addr_t *peer_addr, u16_t peer_port) {
  ntp_client_t *client = (ntp_client_t *)arg;
  client->processed = true;
  client->abs_time_at_ntp_resp = get_absolute_time();
  if (p->tot_len != NTP_MSG_LEN) {
    WARNING_printf("UDP response length %d, expected %d\n", p->tot_len,
                   NTP_MSG_LEN);
    client->ntp_err = ERR_VAL;
    goto cleanup;
  }
  uint8_t *payload = (uint8_t *)(p->payload);
  uint8_t resp_mode = payload[0] & NTP_MODE_MASK;
  uint8_t resp_stratum = payload[1];

  if (!ip_addr_cmp(&client->ntp_ipaddr, peer_addr)) {
    WARNING_printf("Mismatched IP addr: expect %s found %s\n",
                   ip4addr_ntoa(&client->ntp_ipaddr), ip4addr_ntoa(peer_addr));
    client->ntp_err = ERR_VAL;
    goto cleanup;
  }
  if (peer_port != client->ntp_port) {
    WARNING_printf("Mismatched Port: expect %d found %d\n", client->ntp_port,
                   peer_port);
    client->ntp_err = ERR_VAL;
    goto cleanup;
  }
  if (resp_mode != NTP_MODE_SERVER) {
    WARNING_printf("Unexpected NTP mode: expect %d found %d\n", NTP_MODE_SERVER,
                   resp_mode);
    client->ntp_err = ERR_VAL;
    goto cleanup;
  }
  if (resp_stratum == NTP_STRATUM_INVALID) {
    WARNING_printf("Invalid NTP stratum\n");
    client->ntp_err = ERR_VAL;
    goto cleanup;
  }
  client->ntp_err = ERR_OK;
  uint8_t seconds_buf[4] = {0};
  pbuf_copy_partial(p, seconds_buf, sizeof(seconds_buf), 40);
  uint32_t seconds_since_1900 = seconds_buf[0] << 24 | seconds_buf[1] << 16 |
                                seconds_buf[2] << 8 | seconds_buf[3];
  uint32_t seconds_since_1970 = seconds_since_1900 - NTP_DELTA_SECONDS;
  client->epoch = seconds_since_1970;
  INFO_printf("got ntp response: %llu\n", client->epoch);

cleanup:
  pbuf_free(p);
}

err_t ntp_client_init(ntp_client_t *client, ip_addr_t ntp_ipaddr,
                      uint16_t ntp_port) {
  client->ntp_ipaddr = ntp_ipaddr;
  client->ntp_port = ntp_port;
  client->processed = false;
  client->pcb = udp_new_ip_type(IPADDR_TYPE_V4);
  if (!client->pcb) {
    CRITICAL_printf("Failed to allocate for NTP's UDP control block\n");
    return ERR_MEM;
  }
  udp_recv(client->pcb, ntp_resp_handler, client);
  return ERR_OK;
}

void ntp_client_close(ntp_client_t *client) {
  if (client->pcb) {
    udp_remove(client->pcb);
    client->pcb = NULL;
  }
}

/**
 * This method will handle the UDP PCB
 */
err_t ntp_client_sync_timeout_ms(ntp_client_t *client, uint32_t timeout_ms) {
  cyw43_arch_lwip_begin();
  cyw43_arch_poll();
  struct pbuf *ntp_req = pbuf_alloc(PBUF_TRANSPORT, NTP_MSG_LEN, PBUF_RAM);
  if (!ntp_req) {
    WARNING_printf("Failed to allocate %d pbuf\n", NTP_MSG_LEN);
    return ERR_MEM;
  }
  uint8_t *payload = (uint8_t *)ntp_req->payload;
  memset(payload, 0, NTP_MSG_LEN);
  payload[0] = NTP_LI_NO_WARNING | NTP_VN_VERSION_3 | NTP_MODE_CLIENT;
  udp_sendto(client->pcb, ntp_req, &client->ntp_ipaddr, client->ntp_port);
  pbuf_free(ntp_req);
  cyw43_arch_lwip_end();

  uint32_t timeout_begin = to_ms_since_boot(get_absolute_time());
  while ((to_ms_since_boot(get_absolute_time()) - timeout_begin) < timeout_ms &&
         !client->processed) {
    cyw43_arch_poll();
  }

  if (!client->processed) {
    return ERR_TIMEOUT;
  }
  return client->ntp_err;
}

/**
 * Return the current time
 */
time_t get_current_epoch(ntp_client_t *client) {
  uint64_t diff_us =
      absolute_time_diff_us(client->abs_time_at_ntp_resp, get_absolute_time());
  return client->epoch + (us_to_ms(diff_us) / 1000u);
}
```

Finally let's combine DNS and NTP to get a clock going:

```c
dns_result_t dns;
dns_result_init(&dns);
dns_gethostbyname_blocking(NTP_HOSTNAME, &dns);
if (dns.resolved) {
  printf("%s resolved to %s\n", NTP_HOSTNAME, ipaddr_ntoa(&dns.addr));
}

ntp_client_t ntp_client;
ntp_client_init(&ntp_client, dns.addr, NTP_PORT);
if (ntp_client_sync_timeout_ms(&ntp_client, NTP_TIMEOUT_MS) != ERR_OK) {
  printf("Failed to sync time\n");
  exit(-1);
}
ntp_client_close(&ntp_client);

while (1) {
  printf("Current UNIX epoch %llu\n", get_current_epoch(&ntp_client));
  sleep_ms(1000);
}
```

Verify by comparing with the clock on a desktop:

```bash
while true; do clear; date "+%s"; sleep 1; done
```