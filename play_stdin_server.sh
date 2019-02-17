#!/bin/bash
# Scratchpad: For encryption 
# echo "hello" | openssl enc -aes-256-ctr -a -k PaSSw
#echo U2FsdGVkX19MTXVYuVwVY8dnc9W+kQ== |  openssl enc -d -a -aes-256-ctr -k PaSSw


CONTROLLER_PIPE_NAME=pipe
CONTROLLER_PIPE_FILE=/tmp/$CONTROLLER_PIPE_NAME
CONTROLLER_PORT=1337
CONTROLLER_PASSWORD=PaSSw # Not currently used

AUDIO_SERVER_IS_RUNNING=false
AUDIO_SERVER_PID=0

AUDIO_SERVER_PLAYER="ffplay -nodisp -i -" 


# Create the pipe 
setup_server_fifo () {
  mkfifo $1
  return
}

################
# Server commands
#################
# EXIT, kill the whole server
server_exit (){
  echo "GOODBYE!" > $CONTROLLER_PIPE_FILE;
  rm $CONTROLLER_PIPE_FILE
  kill -- -$$;
}

# HELLO - for testing connection, ensuring an audio server can start
server_hello () {
  echo "HELLO" > $CONTROLLER_PIPE_FILE;
}

# NEW, create audio server randomized port and send the port
server_new_stream () {
  PORT=$(( (RANDOM % 3000 ) + 1030 ))
  echo "Starting new audio server on port $PORT"
  netcat -lp $PORT | $AUDIO_SERVER_PLAYER &

  AUDIO_SERVER_PID=$!
  AUDIO_SERVER_IS_RUNNING=true
#  echo $AUDIO_SERVER_PID > $CONTROLLER_PIPE_FILE
#  echo $! > $CONTROLLER_PIPE_FILE

  echo $PORT > $CONTROLLER_PIPE_FILE;
}


# respond to commands from client
command_respond () {
case "$1" in
  "HELLO") server_hello
    ;;
  "BYE") server_exit
    ;;
  "NEW") server_new_stream
    ;;
esac
}

# Create the pipe for commands
setup_server_fifo $CONTROLLER_PIPE_FILE

# Main loop of server
# constantly pipe fifo into netcat
# constantly read netcat resp and execute related command
# Controller pipe is for messages to clients
while true;
do cat $CONTROLLER_PIPE_FILE;
done |
netcat -l -k -p $CONTROLLER_PORT |
while read line
do
  command_respond $line
done

