part of server;

class Server{

  Storage localStorage = window.localStorage;
  String firebaseURL;
  Firebase firebase;

  Server(String firebaseRef){

    firebaseURL = "https://" + firebaseRef + ".firebaseio.com";

    firebase = new Firebase(firebaseURL);
  }

  Future<String> getString(String child) async{

    Event event = await firebase.child(child).onValue.first;

    String data = event.snapshot.val();

    return data;

  }

  setInt(String child, int number)async{
    firebase.child(child).set(number);
  }

  Future<int> getInt(String child) async{

    Event event = await firebase.child(child).onValue.first;

    int data = event.snapshot.val();

    return data;

  }

  Future<int> getNextPlayerId()async{

    String saved = localStorage["id"];


    if(saved == null) {

      String child = 'player_nextid';

      int data = await getInt(child);

      localStorage["id"] = data.toString();

      await setInt(child, data+1);

      return data;

    } else return int.parse(saved);


  }

  Future<List<String>> getWords()async{

    String saved = localStorage["words"];

    if(saved != null) return JSON.decode(saved);

    print('getting dictionary from firebase');

    Event event = await firebase.child('words').onValue.first;

    var data = event.snapshot.val();

    localStorage["words"] = data;

    List<String> wordArray = JSON.decode(data);

    localStorage["words"] = data;

    return wordArray;
  }

  Future<Map> getGameDetails(int id)async{

    Event event = await firebase.child('games/$id').onValue.first;

    Map data = event.snapshot.val();

    print(data);

    return data;
  }


  Future<int> addGame(int size, int playerNumber, String letters)async{

    int gameNumber = await getInt('game_next');

    setInt('game_next', gameNumber + 1);

    Map gameMap = new Map();

    gameMap['game_id'] = gameNumber;

    gameMap['size'] = size;

    gameMap['number_players'] = playerNumber;

    gameMap['letters'] = letters;

    gameMap['status'] = 'waiting';

    List players = new List();
    players.add(playerId);

    gameMap['players'] = players;

    await firebase.child('games/$gameNumber').set(gameMap);

    await setGameListener(gameMap);

    return gameNumber;

  }

  bool isThisMyGame(Map gameMap){

    List<String> gamePlayers = gameMap['players'];

    if(gamePlayers == null) return false;

    if(gamePlayers.contains(playerId)) return true;

    return false;
  }

  setPlayerOnline (String id)async{

    Map playerMap = new Map();

    playerMap['player_id'] = id;

    playerMap['game'] = "";

    playerMap['status'] = 'online';

    await firebase.child('players/$id').set(playerMap);

    await firebase.child('players/$id').onDisconnect.remove();
  }

  joinGame(Map gameMap)async{

    int gameNumber = gameMap['game_id'];

    List<String> gamePlayers = gameMap['players'];

    print('join game before $gamePlayers');

    if(!gamePlayers.contains(playerId))gamePlayers.add(playerId);

    print('join game after $gamePlayers');

    gamePlayers.shuffle();

    await firebase.child('games/$gameNumber/players').set(gamePlayers);

    setGameListener(gameMap);
  }

  setGameListener(Map gameMap)async{

    await firebase.child('games/${gameMap['game_id']}/players').onValue.listen((e)async{

      List<String> gamePlayers = e.snapshot.val();

      gameMap['players'] = gamePlayers;

      if(gamePlayers.length == gameMap['number_players']){

        gameMap['status'] = 'full';

        bool allPlayersReady = true;

        List<Map> playerList = new List();

        for(String playerString in gamePlayers){

          var e = await firebase.child('players/$playerString/').onValue.first;

          Map player = e.snapshot.val();

          playerList.add(player);

          if(player['status'] != 'online') allPlayersReady = false;

        }

        if(allPlayersReady){

          for(Map player in playerList){

            player['status'] = 'in_game';
            player['game'] = gameMap['game_id'];

            await firebase.child('players/${player['player_id']}/').set(player);
          }

          gameMap['status'] = "in_game";

          await firebase.child('games/${gameMap['game_id']}/status').set('in_game');

          startOnlineGame(null, gameMap);
        }
      }

    });


  }


  List<String> getPlayerList(String string){

    List<String> gamePlayers = new List();

    if(string == null || string == "") return gamePlayers;
    else gamePlayers = string.split(',');

    print('from getList $gamePlayers');

    return gamePlayers;
  }

  String getPlayerString(List<String> stringList){

    String string ="";

    switch(stringList.length){

      case 0: string =  null;
      break;

      case 1: string =  '${stringList[0]}';
      break;

      case 2: string =  '${stringList[0]},${stringList[1]}';
      break;

      case 3: string =  '${stringList[0]},${stringList[1]},${stringList[2]}';
      break;

      case 4: string =  '${stringList[0]},${stringList[1]},${stringList[2]},${stringList[3]}';
      break;



    }

    print('from getString $string');

    return string;
  }


}