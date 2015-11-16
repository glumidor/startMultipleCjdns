you started (a monster) bunch of cjdroutes?
with the wrong config? forgot something?
here's how to ger rid of it:

<code> pgrep cjd </code>

shows a (huge) list of process id's. all related to cjdroute

take this list and kill every pid from it:

<code> pgrep cjd | xargs kill </code>

voila
