//Import libraries we need.
import Web3 from "web3";
import contract from "truffle-contract";
import "./style.css";
import $ from "jquery";

//Import out contract artifacts and trun them into usable abstractions.
import tictactoe_artifacts from "../../build/contracts/TicTacToe.json";

//TicTacToe is our usable abstraction, which we'll use through the code below.
var TicTacToe = contract(tictactoe_artifacts);
var tictactoeinstance;
var account;
var accounts;


const App = {
  web3: null,
  account: null,
  meta: null,


  start: async function() {
    const { web3 } = this;

    TicTacToe.setProvider(web3.currentProvider);

    await web3.eth.getAccounts(function(err,accs){
      if(err!=null){
        alert("There was an error fetching your accounts.");
        return;
      }

      if(accs.length==0){
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
      }

      accounts = accs;
      account = accounts[0];
      console.log(account);
    });
  },

  useAccountOne: function(){
    account = accounts[1];
    console.log("Change to the second account:" ,account);
  },

  createNewGame: function(){
    //console.log("createNewGame Called");
    TicTacToe.new({from: account,value: Web3.utils.toWei('0.1','ether'),gas:3000000}).then(instance=>{
      tictactoeinstance = instance;


      var playerJoinedEvent = tictactoeinstance.PlayerJoined_123456();
      playerJoinedEvent.on("data",(error,eventObj) => {
        if(!error){
          console.log(eventObj);

        }else{
          console.error(error);
        }
      });


      var nextplayerEvent = tictactoeinstance.NextPlayer_123456();
      nextplayerEvent.on("data", App.nextPlayer(nextplayerEvent));

      console.log(instance);
    }).catch(error=>{
      console.log(error);
    })
  },


  joinGame:function(){
    var gameAddress = prompt("Address of the Game");
    if(gameAddress != null){
      TicTacToe.at(gameAddress).then(instance=>{
          tictactoeinstance = instance;
          return tictactoeinstance.joinGame({from: account,value: Web3.utils.toWei('0.1','ether'),gas:3000000});
      }).then(txResult =>{
          console.log(txResult);

          var nextplayerEvent = tictactoeinstance.NextPlayer_123456();
          nextplayerEvent.on("data", App.nextPlayer(txResult.logs[1]));
      })
    }
  },

  nextPlayer: function(error, eventObj){
    //Update the board
    App.printBoard();

    if(eventObj.args.player == account){
      ///our turn
      /*Set the On-click Event Listerner*/
      for(var i = 0; i < 3; i++){
        for(var j = 0; j < 3; j++){
          $($("#board")[0].children[0].children[i].children[j]).off('click').click({x:i , y:j},App.setStone);
        }
      }
    }else{
      //other player's turn
    }
  },


  setStone: function(event){
    console.log(event);

    //Turn off onclick handler
    for(var i = 0; i < 3; i++){
      for(var j = 0; j < 3; j++){
        $($("#board")[0].children[0].children[i].children[j]).prop('onclick',null).off('click');
      }
    }
    tictactoeinstance.setStone(event.data.x, event.data.y, {from:account}).then(txResult=>{
      console.log(txResult);
      App.printBoard();
    })
  },

  printBoard: function(){
    tictactoeinstance.getBoard.call().then(board =>{
      for(var i=0; i < board.length; i++)
      {
          for(var j=0; j < board.length; j++){
            if(board[i][j] == account){
              $("#board")[0].children[0].children[i].children[j].innerHTML = "X";
            }else if(board[i][j] != 0){
              $("#board")[0].children[0].children[i].children[j].innerHTML = "O";
            }
          }
      }
    })
  }

};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
