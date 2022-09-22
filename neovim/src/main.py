from dijkstra import dijkstra

N = 5
NODES = [x for x in range(N)]
EDGES = [
    (0, 1, 5),
    (0, 3, 9),
    (0, 4, 1),
    (1, 2, 2),
    (2, 3, 6),
    (3, 4, 2)
]

if __name__ == "__main__":
    start = 0
    dists = dijkstra(start, NODES, EDGES)
    for dest, dist in sorted(dists.items()):
        print(f"The shortest path from {start} to {dest} is {dist}")
