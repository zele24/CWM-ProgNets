 /*
 *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |   Player In    |      Team      |    Has Flag    |      Op       |
 * +----------------+----------------+----------------+---------------+
 * |            X-Location           |           Y-Location           |
 * +----------------+----------------+----------------+---------------+
 * |                             Assignment                           |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 
  *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |      P         |       4        |     Version    |     Op        |
 * +----------------+----------------+----------------+---------------+
 * |                              Operand A                           |
 * +----------------+----------------+----------------+---------------+
 * |                              Operand B                           |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 
 */
 
 #include <core.p4>
 #include <v1model.p4>
 
 /*
 * Define the headers the program will recognize
 */
typedef bit<48> macAddr_t;
/*typedef bit<16> location_t;*/

/*
 * Standard Ethernet header
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*All the fixed data values
*/

const bit<16> PLAYER_ETYPE = 0x1234;
const bit<8> PLAYER_1 = 0x30; // 0
const bit<8> PLAYER_0 = 0x31; // 1
const bit<8> PLAYER_A = 00000000; // A
const bit<8> PLAYER_B = 00000001; // B
const bit<8> PLAYER_IN = 0x30; // 0

//operations
const bit<8> PLAYER_MOVE = 0x4d; // 'M'
const bit<8> PLAYER_CHECK = 0x43; // 'C'
const bit<8> PLAYER_CAPT = 0x46; // 'F'
const bit<8> PLAYER_WIN = 0x57; // 'W'
const bit<8> PLAYER_STATE = 0x53; // 'S'
const bit<8> PLAYER_INIT = 0x49; // 'I'


/* Registers to store changing values
 */
 //Register called 'rx', stores the 4 x-locations of the 4 players, assignment is 8 bit though, so the redister size is 2^8
register<bit<16>>(8) rx;
 //Register called 'ry', stores the 4 y-locations of the 4 players
register<bit<16>>(8) ry;
 //Register called 'inPlay', stores the 'in play?' states of the 4 players
register<bit<8>>(8) inPlay;
 //Register called 'Flag', stores the 'Has-Flag' states of the 4 players
register<bit<8>>(8) Flag;

 

header player_t {
    bit<8>  ingame;
    bit<8>  team;
    bit<8>  flag;
    bit<8>  op;
    bit<16>  x_loc;
    bit<16>  y_loc;
    bit<32>  ass;
    bit<32>  res;

}
 
 
struct headers {
    ethernet_t   ethernet;
    player_t     player;
}



struct metadata {
}



/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            PLAYER_ETYPE : parse_player;
            default      : accept;
        }
    }

   /* state check_player {
    Seemingly all this does is check ehat the 1st header is 'P' the second is '4' and the third is the version
        transition select(packet.lookahead<player_t>().ingame,
        packet.lookahead<player_t>().team,
        packet.lookahead<player_t>().flag) {
            (PLAYER_MOVE, PLAYER_CHECK, PLAYER_CAPT) : parse_player;
            
            default                          : accept;
        }
        }*/
    

    state parse_player {
        packet.extract(hdr.player);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

 
 
 
 /*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    action send_back(bit<32> result) {
  
  //bit<8> playing, bit<8> hasflag, bit<16> X, bit<16> Y, from the input to the function, but we only need to send back the result, all the rest is on our side
         hdr.player.res = result;

/*
I don't care about the mac addresses, just sending it back

         macAddr_t tmp_mac;
         tmp_mac = hdr.ethernet.dstAddr;
         hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
         hdr.ethernet.srcAddr = tmp_mac;
*/
         
         standard_metadata.egress_spec = standard_metadata.ingress_port;
 
 
        
    }

    action operation_move() {
    	
    	//defining temp variables to carry the values from the registers, then writing the new x and y locations of the player into the correct position in the register
    	
   	
    	bit<16> X;
    	bit<16> Y;
      	    	
    	bit<32> index;
    	index = (bit<32>) hdr.player.ass;
    	X = hdr.player.x_loc;
    	Y = hdr.player.y_loc;
    	rx.write(index, X);
    	ry.write(index, Y);
    	
 
    	
    	bit<32> message;
    	message = 0x73777368;  //Returns the letter swsh
    
        send_back(message);
        //hdr.player.res = message;
        //standard_metadata.egress_spec = standard_metadata.ingress_port;
 
    }
    
    action operation_state() {
    	
    //Gives you the player you requested's locations   	
   	
   	bit<16> X;
    	bit<16> Y;
    	bit<32> index;
    	index = (bit<32>) hdr.player.ass;
    	rx.read(X, index);
    	ry.read(Y, index);
   	
   	
    	
    	bit<32> message;
    	bit<16> hexX;
    	bit<8> hexY;
    	
    	hexX = 0;
    	hexY = 0;
    	
    	// I have to convert the X and Y coordinated but can't just concatinate the digits
    	
    	if (X == 0) {
    	  hexX = 0x302C;
    	}
    	if (X == 1) {
    	  hexX = 0x312C;
    	}
    	if (X == 2) {
    	  hexX = 0x322C;
    	}
    	if (X == 3) {
    	  hexX = 0x332C;
    	}
    	if (X == 4) {
    	  hexX = 0x342C;
    	}
    	if (X == 5) {
    	  hexX = 0x352C;
    	}
    	if (X == 6) {
    	  hexX = 0x362C;
    	}
    	if (X == 7) {
    	  hexX = 0x372C;
    	}
    	if (X == 8) {
    	  hexX = 0x382C;
    	}
    	if (X == 9) {
    	  hexX = 0x392C;
    	}
    	
    	if (Y == 0) {
    	  hexY = 0x30;
    	}
    	if (Y == 1) {
    	  hexY = 0x31;
    	}
    	if (Y == 2) {
    	  hexY = 0x32;
    	}
    	if (Y == 3) {
    	  hexY = 0x33;
    	}
    	if (Y == 4) {
    	  hexY = 0x34;
    	}
    	
    	

    	bit<8> still;
    	bit<8> alive;
    	inPlay.read(still, index);
    	alive = 0x2b;
    	
    	if (still == 1) {
    	  alive = 0x2b;
    	}
    	if (still == 0) {
    	  alive = 0x78;
    	}    	
 
 
 
 
 
 
 
    	message = hexX ++ hexY ++ alive;
    	
    	
    
        send_back(message);
        //hdr.player.res = message;
        //standard_metadata.egress_spec = standard_metadata.ingress_port;
 
    }


    action operation_check() {
    	
    	//we will ignore the blank x&y cordinated in the initial message as these will be full of zeros from python
    	bit<16> X;
    	bit<16> Y;
    	bit<32> index;
    	index = (bit<32>) hdr.player.ass;
    	rx.read(X, index);
    	ry.read(Y, index);
    	
    	//Defining variables for the assignments of the other team's players
    	bit<32> P1;
    	bit<32> P2;
    	
    	//Getting the player's team
    	bit<32> side;
    	side = (bit<32>) hdr.player.team;
    	if (side == 0) {
    	  P1 = 2;
    	  P2 = 3;
    	
    	} else {
    	  P1 = 0;
    	  P2 = 1;
    	}
    	
    	//We now need to read all the locations of players of the opposite team and see if any are on the same spot or adjacent
    	
   
    	/*location_t X1;
    	location_t Y1;
    	location_t X2;
    	location_t Y2;*/
    	
    	bit <16> X1;
    	bit <16> Y1;
    	bit <16> X2;
    	bit <16> Y2;
    	
    	rx.read(X1, P1);
    	ry.read(Y1, P1);    	
    	rx.read(X2, P2);
    	ry.read(Y2, P2);
    	
    	bit<1> sameX1;
    	bit<1> sameX2;
    	bit<1> sameY1;
    	bit<1> sameY2;
    	
    	bit<32> message;
    	
    	    	
    	//Comparing locations, don't do negative!!!
    	bit<16> diffX1;
    	bit<16> diffY1;
    	bit<16> diffX2;
    	bit<16> diffY2;
    	
    	if (X1 > X) {
    	  diffX1 = X1 - X;
    	}
    	if (X1 > X) {
    	  diffX1 = X1 - X;
    	}
    	//////////////Continue this code

    	
    	
    	
    	
    	diffX1 = X1 - X;
    	diffX2 = X2 - X;
    	diffY1 = Y1 - Y;
    	diffY2 = Y2 - Y;
    	
    	
    	/*Or 1 away:
    	| diffX1 == -1 | diffX1 == 1
    	*/
    	
    	if (diffX1 == 0) {
    	  sameX1 = 1;
    	} else {
    	  sameX1 = 0;
    	}

    	if (diffX1 == 1) {
    	  sameX1 = 1;
    	} else {
    	  sameX1 = 0;
    	}



    	if (diffX2 == 0) {
    	  sameX2 = 1;
    	} else {
    	  sameX2 = 0;
    	}
    	
    	if (diffX2 == 1) {
    	  sameX2 = 1;
    	} else {
    	  sameX2 = 0;
    	}
    	
    	if (diffY1 == 0) {
    	  sameY1 = 1;
    	} else {
    	  sameY1 = 0;
    	}
    	if (diffY1 == 1) {
    	  sameY1 = 1;
    	} else {
    	  sameY1 = 0;
    	}

    	if (diffY2 == 0) {
    	  sameY2 = 1;
    	} else {
    	  sameY2 = 0;
    	}
    	
    	if (diffY2 == 1) {
    	  sameY2 = 1;
    	} else {
    	  sameY2 = 0;
    	}
    	
    	
    	
    	const bit<8> outgame = 0;
    	
    	if (sameX1 == 1) {
    	  if (sameY1 == 1) {
    	  message = (bit<32>)P1;    //Returns the player number who got caught
    	  //inPlay.write(P1, outgame);
    	  } else {
    	    message = 0x43; //returns 'C' for clear
    	  }
    	} else if (sameX2 == 1) {
    	    if (sameY2 == 1) {
    	      message = (bit<32>)P2;    //Returns player 2 only if they're adjacent and player 1 isn't
    	      //inPlay.write(P2, outgame);
    	  } else {
    	    message = 0x43; //returns 'C' for clear
    	  }
    	  } else {
    	    message = 0x43; //returns 'C' for clear
    	  }
    	
    	
    
        send_back(message);
    }
    
    
    action operation_init() {
    	
    	//making all players as in and not with flag
    	
    	const bit<8> inGame = 1;
    	const bit<8> flagless = 0;
    	const bit<8> teamA = 0;
    	const bit<8> teamB = 1;
    	const bit<32> A1 = 0;
    	const bit<32> A2 = 1;
    	const bit<32> B1 = 2;
    	const bit<32> B2 = 3;
    	
    	inPlay.write(A1, inGame);
    	inPlay.write(A2, inGame);
    	inPlay.write(B1, inGame);
    	inPlay.write(B2, inGame);
    	
    	Flag.write(A1, flagless);
    	Flag.write(A2, flagless);
    	Flag.write(B1, flagless);
    	Flag.write(B2, flagless);
        	
    	
    	bit<32> message;
    	message = 0x49;  //Returns the letter 'I' for initialised
    
        send_back(message);
    }
    
    action operation_capture() {
    	
    	//checks player's team, then checks if they are adjacent to the other team's flag
    	

    	bit <16> X;
    	bit <16> Y;
    	
    	bit<32> index;
    	bit<8> activeTeam;

    	
    	index = (bit<32>) hdr.player.ass;
    	activeTeam = hdr.player.team;

	//Getting current position of player
    	rx.read(X, index);
    	ry.read(Y, index);
    	
    
    	bit <16> Fx;
    	bit <16> Fy;
    	
    	//Getting the coordinate of the opposite team's flag
    	
    	if (activeTeam == 0) {
    	  Fx = 0;
    	  Fy = 2;
    	} else {
    	  Fx = 9;
    	  Fy = 2;
    	}
    	
    	bit<2> sameX;
    	bit<2> sameY;
    	bit<32> message;
    	
    	
    	
    	//Comparing locations
    	if (Fx-X == 0) {
    	  sameX = 1;
    	} else {
    	  sameX = 0;
    	}
    	if (Fx-X == 1) {
    	  sameX = 1;
    	} else {
    	  sameX = 0;
    	}
    	if (Fx-X == -1) {
    	  sameX = 1;
    	} else {
    	  sameX = 0;
    	}
    	
    	     
    	if (Fy-Y == 0) {
    	  sameY = 1;
    	} else {
    	  sameY = 0;
    	}
    	if (Fy-Y == 1) {
    	  sameY = 1;
    	} else {
    	  sameY = 0;
    	}
    	if (Fy-Y == -1) {
    	  sameY = 1;
    	} else {
    	  sameY = 0;
    	}  
    	
    	

    	if (sameX == 1) {
    	  if (sameY == 1) {
    	    //Flag.write(index, 1);
    	    message = 0x54616721; //returns 'Tag!'
    	} else {
    	  message = 0x46; //returns 'F' for failed
    	} 
    	} else {
    	  message = 0x46; //returns 'F' for failed
    	  
    	  
    	}

    	
        send_back(message);
    }

    action operation_drop() {
        mark_to_drop(standard_metadata);
    }
    
    
    

    table calculate {
        key = {
            hdr.player.op        : exact;
        }
        actions = {
            operation_move;
            operation_check;
            operation_capture;
            //operation_win;
            operation_state;
            operation_init;
            operation_drop;
        }
        const default_action = operation_drop();
        const entries = {
            PLAYER_MOVE : operation_move();
            
            PLAYER_CHECK: operation_check();
            PLAYER_CAPT : operation_capture();
            //PLAYER_WIN  : operation_win();
            PLAYER_STATE: operation_state();
            PLAYER_INIT : operation_init();
        }
    }

    apply {
    
    // performs the operation if it is one of the ones listed, else it drops the packet
        if (hdr.player.isValid()) {
            calculate.apply();
            /*
            if (hdr.player.op == PLAYER_MOVE) {
            hdr.player.res = 40;
            } else {
            hdr.player.res =404;
            }
            standard_metadata.egress_spec = standard_metadata.ingress_port;       
        */
        } else {
            operation_drop();
        }
        
        //standard_metadata.egress_spec = standard_metadata.ingress_port; 
    }
    
}
 
 
 
 
 
 /*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {

     }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.player);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
