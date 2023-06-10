# xuganyu96.github.io
My personal website

## Managing dot files

```bash
# From project root
ln -s $(pwd)/tmux.conf ~/.tmux.conf
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
```

## Personal project ideas
- [x] A Redis client and server from scratch [mini-redis](https://github.com/xuganyu96/mini-redis)
- [ ] Toy TLS implementation [tls-core](https://github.com/xuganyu96/rust-tls-core)
- [ ] Documents about running Airflow on ECS Fargate [aws-ecs-fargate](https://github.com/xuganyu96/airflow-ecs-fargate)
