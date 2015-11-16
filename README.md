# startMultipleCjdns
found the script "startMultipleCjdns.sh" at fc00.org, used it ... and needed to customize it on my own.
                                                                  I use ec2 at amazon, I also customzied a bit for this ...
here is my current state

currently it fires up a configurable number of cjdroute instances with freshly generated configs. a whole bunch of very-unique-never-seen-before-and-after-instances of cjdns nodes. the script keeps a variable c for gathering all generated nodes for adding them into following nodes to connect to. first node starts, second nodes starts and connects to first node. third node connects to first and second, tenth node connects to the first 9 nodes. when all nodes are launched, every node should be connected with every other node (mesh_percentace=100).

if you don't want/need/like a fullmesh, you can set the mesh_percentage to ... say ... 30

the list of generated nodes will still be gathered, but every entry is added only with at 30/100 random probability.
that's not 30% from all, I know, but it's a 30% probability of every node to get onto the list to be connected by the later ones. if you're unlucky and fall into the 70%, no other node will connect you... you just have your peer_* homebase

so far... play with it

thanks
