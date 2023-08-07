# xuganyu96.github.io
My personal website: xuganyu96.github.io

## Managing dot files

```bash
# From project root
ln -s $(pwd)/tmux.conf ~/.tmux.conf
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
```

## Personal project ideas
- [ ] Cryptopals challenges
- [ ] Toy TLS implementation [tls-core](https://github.com/xuganyu96/rust-tls-core) (temporarily de-prioritized due to personal circumstances)
- [ ] Documents about running Airflow on ECS Fargate [aws-ecs-fargate](https://github.com/xuganyu96/airflow-ecs-fargate)
- [ ] Build another Flask application [openjielong](https://github.com/xuganyu96/openjielong)  
This time focus on building out some boilerplate stuff that can be used in subsequent projects
- [ ] Learn about self-hosting `code-server`
- [x] A Redis client and server from scratch [mini-redis](https://github.com/xuganyu96/mini-redis)