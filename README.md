**beanwatch** logs the user_beancounters file on Virtuozzo containers. It's pretty simple in what it does:

1. Gets the values of numproc and oomguarpages and saves them
2. Does an infinite check to see if the values of them has increased since logging started
3. If so, log into a file that $limit was hit and what the current value is
4. Goto 2
