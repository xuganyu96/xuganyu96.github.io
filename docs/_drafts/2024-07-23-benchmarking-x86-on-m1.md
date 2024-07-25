```bash
git clone https://github.com/pq-crystals/kyber
cd kyber
arch -x86_64 make -C ref speed
arch -x86_64 ./ref/test_speed512
arch -x86_64 make -C ref clean
```