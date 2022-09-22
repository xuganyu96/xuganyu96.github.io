from heapq import heappop, heappush
from typing import Dict, List, Tuple

def build_adj(
    nodes: List[int],
    edges: List[Tuple[int, int, int]]):
    adj = {node: {} for node in nodes}
    for x in nodes:
        for y in nodes:
            adj[x][y] = float("inf")
    for x, y, w in edges:
        adj[x][y] = adj[y][x] = w
    
    return adj

def dijkstra(
    start: int,
    nodes: List[int],
    edges: List[Tuple[int, int, int]]
) -> Dict[int, int]:
    """Given a list of nodes and a list of edges return a dictionary that maps
    node to the shortest distance from the start. If the node cannot be reached,
    put -1. Each edge is 
    """
    adj = build_adj(nodes, edges)
    pq = [(0, start)]  # maintains the next nearest nodes
    dists = {}

    while len(pq) > 0:
        dist, node = heappop(pq)
        if node not in dists:
            dists[node] = dist
        
        for dst, weight in adj[node].items():
            if dst not in dists and weight != float("inf"):
                heappush(pq, (dist + weight, dst))
    
    return dists
