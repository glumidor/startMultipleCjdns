#!/bin/bash
my_own_ip=$(curl http://icanhazip.com 2>/dev/null)  # using with amazon ec2

###############################################################################
# CONFIG

project="yourproject"    # project name, used for dynamic hostnames (peerNames) and conf files
domain="yourdomain"   # use this for naming your nodes:
                      # gives hosts with "peerName":"node$i.$project.$domain"
                      # use it wisely...

num_of_nodes=30       # how many cjdroute instances should be fired off
mesh_percentage=100   # 100% meshes all nodes together (fullmesh), 
                      # 30% connects each node to only random 30% of the others

# Where nodes connect to. our homebase, if you will
peer_ip=$my_own_ip  # just for amazon use... feel free to enter you own cjdns node
peer_port="25ex2"
peer_pw="s47qpzEXAMPLEq87bdEXAMPLEpf79p"
peer_pk="7g0r4fy99v79jEXAMPLEjuumltm3EXAMPLErs7kutdEXAMPLE5l0.k"
peer_name="yourhomebase" # name you homebase


# RPC settings for nodes
rpc_bind="127.0.0.1"
rpc_pw="hunter"
rpc_firstport=50000

cjdns_path="/root/cjdns"
###############################################################################


mkdir -p mapper-confs
# rm -f mapper-confs/*   # clean config dir? decide on your own

c=$(echo '"connectTo":')
c=$c$(echo '{"'$peer_ip':'$peer_port'":{"peerName":"'$peer_name'","password":"'$peer_pw'","publicKey":"'$peer_pk'"},')

for i in $(seq 1 $num_of_nodes)
do
	echo "Starting mapper node $i/$num_of_nodes"

	nodename=node${i}.${project}.${domain}

	file=mapper-confs/$nodename.conf
	rpcport=$(($rpc_firstport + $i - 1))

	$cjdns_path/cjdroute --genconf --no-eth > $file # to get new calculated values

	# extract the values
	privatekey=$(cat $file | egrep '"privateKey":' | awk '{FS="\": \""}{print $2}' | sed "s/[\",]//g" | head -n 1)
	publickey=$(cat $file | egrep '"publicKey":' | awk '{FS="\": \""}{print $2}' | sed "s/[\",]//g" | head -n 1)
	ipv6=$(cat $file | egrep '"ipv6":' | awk '{FS="\": \""}{print $2}' | sed "s/[\",]//g" | head -n 1)
	bindport=$(cat $file | egrep '"bind":' | grep "0.0.0.0" | awk '{FS="\": \""}{print $2}' | sed "s/[\",]//g" | head -n 1 | cut -d ":" -f 2)
	bindpassword=$(cat $file | egrep '"password": "[^"]+", "user":' | awk '{FS="\": \""}{print $2}' | sed "s/[\",]//g" | head -n 1)

	# now we have the new credentials, but... i'd like to use my striped down template. 
	# get rid of the "original" file, get my template and replace the strings:
	rm $file
	cp cjdroute.conf.template $file

	sed -i 's/PRIVATEKEY/'$privatekey'/g' $file
	sed -i 's/PUBLICKEY/'$publickey'/g' $file
	sed -i 's/IPV6/'$ipv6'/g' $file
	sed -i 's/BINDPORT/'$bindport'/g' $file
	sed -i 's/BINDPASSWORD/'$bindpassword'/g' $file
	sed -i 's/RPCPASSWORD/'$rpc_pw'/g' $file
	sed -i 's/127.0.0.1:11234/'"${rpc_bind}"':'"${rpcport}"'/g' $file
	sed -i 's/CONNECTS/'"${c}"'}/g' $file   # the 2. closing bracket is important.
	                                        # don't delete it

	# Disable tun interface
	# sed -i 's/"type": "TUNInterface"/\/\/"type": "TUNInterface"/g' $file

	if [[ $* == *-d* ]]; then
		# Log to stdout
		sed -i 's/\/\/ "logTo":"stdout"/"logTo":"stdout"/g' $file

		gdb $cjdns_path/cjdroute -ex 'set follow-fork-mode child' -ex 'run < '"${file}" -ex 'thread apply all bt' -ex 'quit' > gdb-$i.log 2>&1 &
	else
		$cjdns_path/cjdroute < $file 
		sleep 2
		echo
		$cjdns_path/contrib/python/peerStats
		echo
		echo
	fi

	# after firing this instance off, its save to leave our credentials for the later ones...
  # but... for those who don't want/need/use full meshed, let's drop a random number of connections:
	if [ "$((RANDOM%100+1))" -lt "$mesh_percentage" ]; then   # only $mesh_percentage from 100 come through
  	# create a growing bind-list for each node connecting to each other yet started
  	c=$c$(echo "\"$my_own_ip:$bindport\": {\"peerName\":\"$nodename\", \"password\": \"$bindpassword\", \"publicKey\": \"$publickey\"},")
	fi
done
