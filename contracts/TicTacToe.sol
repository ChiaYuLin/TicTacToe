pragma solidity >=0.5.1;

contract TicTacToe{
    uint constant public gameCost = 0.1 ether;

    uint8 public boardSize=3;

    uint8 movesCounter;

    uint timeToReact = 3 minutes;
    uint gameValidUntil;

    bool gameActive;

    address[3][3] board;

    address payable public player1;
    address payable public player2;

    address payable activePlayer;

    event PlayerJoined_123456(address player);
    event NextPlayer_123456(address player);
    event GameOverWithWin_123456(address winner);
    event GameOverWithDraw_123456();

    event PayoutSuccess_123456(address receiver, uint amount);


    uint balnceToWithdrawPlayer1;
    uint balnceToWithdrawPlayer2;

    constructor() public payable{
       player1 = msg.sender;
       require(msg.value == gameCost);

       gameValidUntil =  now + timeToReact;
    }

    function joinGame() public payable{
       assert(player2 == address(0));

       gameActive = true;

       require(msg.value == gameCost);

       player2 = msg.sender;

       emit PlayerJoined_123456(player2);

       if(block.number % 2 ==0){
           activePlayer = player2;
       }else{
           activePlayer = player1;
       }

       gameValidUntil = now + timeToReact;

       emit NextPlayer_123456(activePlayer);
    }

    function getBoard() public view returns(address[3][3] memory){
        return board;
    }

    function setWinner(address payable player) private{
        gameActive = false;
        //emit an event
        emit GameOverWithWin_123456(player);
        //transfer money to the winner
        uint balanceToPayOut = address(this).balance;

        if(player.send(balanceToPayOut) != true){
            if(player == player1){
                balnceToWithdrawPlayer1 = balanceToPayOut;
            }else{
                balnceToWithdrawPlayer2 = balanceToPayOut;
            }
        }else{
            emit PayoutSuccess_123456(player,balanceToPayOut);
        }

    }

    function withdrawWin() public{
        if(msg.sender == player1){
            require(balnceToWithdrawPlayer1 > 0);
            player1.transfer(balnceToWithdrawPlayer1);
            balnceToWithdrawPlayer1 =0;

            emit PayoutSuccess_123456(player1,balnceToWithdrawPlayer1);
        }else{
            require(balnceToWithdrawPlayer2 > 0);
            player2.transfer(balnceToWithdrawPlayer2);
            balnceToWithdrawPlayer2 =0;

            emit PayoutSuccess_123456(player2,balnceToWithdrawPlayer2);
        }
    }

    function setDraw() private{
        gameActive = false;
        emit GameOverWithDraw_123456();

        //Payout
        uint balnceToPayOut = address(this).balance/2;

        if(player1.send(balnceToPayOut) == false){
            balnceToWithdrawPlayer1 += balnceToPayOut;
        }else{
            emit PayoutSuccess_123456(player1,balnceToPayOut);
        }
        if(player2.send(balnceToPayOut) == false){
            balnceToWithdrawPlayer2 += balnceToPayOut;
        }else{
            emit PayoutSuccess_123456(player2,balnceToPayOut);
        }


    }

    function emergencyCashout() public{
        require(gameValidUntil < now);  //Wait longer than 3 minutes
        //both of players can cash out
        require(gameActive);
        setDraw();
    }

    function setStone(uint8 x, uint8 y) public{
       require(board[x][y] == address(0));
       require(gameValidUntil > now);
       require(msg.sender == activePlayer);

       assert(gameActive);

       assert(x < boardSize);

       assert(y < boardSize);


       board[x][y] = msg.sender;

       movesCounter++;

       gameValidUntil = now + timeToReact;

       //check row
       for(uint i =0; i < boardSize; i++){
           if(board[i][y] != activePlayer){
               break;
           }
           //win
           if(i == boardSize-1){
               //winner
               setWinner(activePlayer);
               return;
           }
       }
       //check column
       for(uint i =0; i < boardSize; i++){
           if(board[x][i] != activePlayer){
               break;
           }
           //win
           if(i == boardSize-1){
               //winner
               setWinner(activePlayer);
               return;
           }
       }
       //check diagonal (0,0),(1,1),(2,2)
       if(x == y){
           for(uint i =0; i < boardSize; i++){
               if(board[i][i] != activePlayer){
                   break;
               }
               //win
               if(i == boardSize-1){
                   //winner
                   setWinner(activePlayer);
                   return;
               }
           }
       }
       //check anti-diagonal (0,2), (1,1), (2,0)
       if(x+y == boardSize-1){
           for(uint i =0; i < boardSize; i++){
               if(board[i][(boardSize-1)-i] != activePlayer){
                   break;
               }
               //win
               if(i == boardSize-1){
                   //winner
                   setWinner(activePlayer);
                   return;
               }
           }
       }
       if(movesCounter == (boardSize**2)){
           //draw
           setDraw();
           return;
       }

       if(activePlayer == player1){
           activePlayer = player2;
       }else{
           activePlayer = player1;
       }

        emit NextPlayer_123456(activePlayer);

    }
}
