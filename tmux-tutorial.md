# Tmux Tutorial

* Start Tmux Session 
  ``` 
  tmux
  ```
2. Split pane vertical - ctrl+b -> %
3. Split pane horizontal - ctrl+b -> "
4. Move between panes - ctrl+b -> right/left/up/down arrow
5. New Window - ctrl+b -> c
6. Move b/w windows - ctrl+b -> <Window number>
7. Rename window - ctrl+b -> , 
8. Close down window/pane - exit
9. Dettach sessions - ctrl+b -> d
10. Attach sessions - tmux attach -t <Window number>
11. List all Sessions - tmux ls
12. Naming and creating a session - tmux new -s <Window Name>
13. Killing session - tmux kill-session -t <Window Name/Number>
