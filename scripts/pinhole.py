#!/usr/bin/env python
"""
usage 'pinhole port host [newport]'

Pinhole forwards the port to the host specified.
The optional newport parameter may be used to
redirect to a different port.

eg. pinhole 80 webserver
    Forward all incoming WWW sessions to webserver.

    pinhole 23 localhost 2323
    Forward all telnet sessions to port 2323 on localhost.

"""

import sys
from socket import *
from threading import Thread
import time
import signal
import os

#enable logging to file
#sys.stdout = open( 'pinhole.log', 'w' )


def log( s ):
    print '%s:%s' % ( time.ctime(), s )
    sys.stdout.flush()


class PipeThread( Thread ):
    pipes = []
    def __init__( self, source, sink ):
        Thread.__init__( self )
        self.source = source
        self.sink = sink

        log( 'Creating new pipe thread  %s ( %s -> %s )' % \
            ( self, source.getpeername(), sink.getpeername() ))
        PipeThread.pipes.append( self )
        log( '%s pipes active' % len( PipeThread.pipes ))

    def run( self ):
        while True:
            try:
                data = self.source.recv( 1024 )
                if not data: break
                self.sink.send( data )
            except:
                break

        log( '%s terminating' % self )
        PipeThread.pipes.remove( self )
        log( '%s pipes active' % len( PipeThread.pipes ))


class Pinhole( Thread ):
    def __init__( self, port, newhost, newport ):
        Thread.__init__( self )
        log( 'Redirecting: localhost:%s -> %s:%s' % ( port, newhost, newport ))
        self.newhost = newhost
        self.newport = newport
        self.sock = socket( AF_INET, SOCK_STREAM )
        self.sock.bind(( '', port ))
        self.sock.listen(5)

    def run( self ):
        while True:
            newsock, address = self.sock.accept()
            log( 'Creating new session for %s %s ' % address )
            fwd = socket( AF_INET, SOCK_STREAM )
            fwd.connect(( self.newhost, self.newport ))
            PipeThread( newsock, fwd ).start()
            PipeThread( fwd, newsock ).start()


if __name__ == '__main__':
    print 'Starting Pinhole'

    if len( sys.argv ) > 1:
        port = newport = int( sys.argv[1] )
        newhost = sys.argv[2]
        if len( sys.argv ) >= 4: newport = int( sys.argv[3] )
        Pinhole( port, newhost, newport ).start()
    else:
        Pinhole( 8080, 'google.com', 80 ).start()
        Pinhole( 8081, 'google.com', 443 ).start()

    try:
        while 1:
            time.sleep(2)
    except (KeyboardInterrupt, SystemExit):
        os.kill(os.getpid(), signal.SIGTERM)

