  import java.text.DecimalFormat;
  import java.util.Collections;
  import java.util.*;
  //DCG
  /*
    Helvetica
    Helvetica-Bold
    Helvetica-BoldOblique
    Helvetica-Light
    Helvetica-LightOblique
    Helvetica-Oblique
    HelveticaNeue
    HelveticaNeue-Bold
    HelveticaNeue-BoldItalic
    HelveticaNeue-CondensedBlack
    HelveticaNeue-CondensedBold
    HelveticaNeue-Italic
    HelveticaNeue-Light
    HelveticaNeue-LightItalic
    HelveticaNeue-Medium
    HelveticaNeue-MediumItalic
    HelveticaNeue-Thin
    HelveticaNeue-ThinItalic
    HelveticaNeue-UltraLight
    HelveticaNeue-UltraLightItalic
  */
  
  ArrayList<Player> players = new ArrayList();
  ArrayList<String> directions = new ArrayList();
  HashMap<String, Location> spawns = new HashMap();
  ArrayList<Location> grid = new ArrayList();
  ArrayList<Location> gridCache = new ArrayList();
  
  PFont f = null;
  int w = 0;
  int h = 0;
  final int topHeight = 50;
  final int pixelSize = 5;
  TopBar bar = null;
  boolean doRespawn = false;
  boolean doFullRender = true;
  boolean doLeaderboard = false;
  boolean runGame = false;
  float framerate = 60;
  double respawnTimer = 3.0;
  double respawnTimerBackup = respawnTimer; // Need a better way to save this variable
  //Screen screen; // Start, Pick Color, game screen
 
 // Return dimensions of screen 
  int getWidth() { return w; }
  int getHeight() { return h; }
  int getTopHeight() { return topHeight; }
  int getPixelSize() { return pixelSize; }
  PFont getFont() { return f; }
  
  ArrayList<Player> getPlayers() { // Yes we don't actually need this getter, but it's good practice
    return players; 
  }
  
  ArrayList<Location> getGridCache() {
    return gridCache; 
  }
  
  void setup() {
    f = createFont("HelveticaNeue-Light", 60, true);
    //println(join(PFont.list(), "\n"));
    directions = new ArrayList();
    directions.add("LEFT");
    directions.add("RIGHT");
    directions.add("DOWN");
    directions.add("UP");
    size(800,720);
    resetGame();
  }
  
  void resetGame() {
    frameRate(framerate);
    w = width;
    h = height;
    if (width % pixelSize != 0 || height % pixelSize != 0) {
      throw new IllegalArgumentException();
    }
    
    this.resetGrid();
    this.doRespawn = false;
    this.runGame = true;
    
    // Later on player 1 and player 2 will be taken from text box input (same for color)
    this.players = new ArrayList();
    
    // Size = 2 for now -- later can do a for loop given the amount of players
    // Four locations = (0 + WIDTH/
    spawns = new HashMap();
    spawns.put("RIGHT", new Location(50, (h - topHeight) / 2)); // LEFT SIDE
    spawns.put("LEFT", new Location(w-50, (h - topHeight) / 2)); // RIGHT SIDE
    spawns.put("DOWN", new Location(w/2, topHeight + 50)); // TOP SIDE
    spawns.put("UP", new Location(w/2, h - 50)); // BOTTOM SIDE
    
    String dir = "RIGHT"; // Need to add players in reverse so that when they respawn, they move in the right direction
    this.players.add(new Player("Player 1", color(255,50,50), 'w', 'a', 's', 'd').setSpawn(spawns.get(dir)).setDirection(dir)); // One player mode breaks game
    dir = "LEFT";
    this.players.add(new Player("Player 2", color(174, 237, 40), 'i', 'j', 'k', 'l').setSpawn(spawns.get(dir)).setDirection(dir));
    //players.add(new Player("Player 3", color(10, 120, 70), 'g', 'v', 'b', 'n'));
    
    this.bar = new TopBar(players, 0, topHeight/2 + topHeight/4);
  }
  
  ArrayList<Player> getLeaderboard() {
    ArrayList<Player> result = new ArrayList(players);
    for (Player player : players) {
        Collections.sort(result);
        Collections.reverse(result);
    }
    return result;
  }
  
  void gameOver() {
    doLeaderboard = true;
    frameRate(2);
    redraw();
  }
  
  void populateGrid() {
    int chance = (int) random(10);
    if (chance <= 3) {
      int hh = ((int) random(50) + 1) * 5;
      int ww = ((int) random(30) + 1) * 5;
      new Wall(w/2, 190, hh, ww).render();
    }
    new PowerUp().populate();
  }
  
  void resetGrid() {
    background(50,50,50);
    this.grid = new ArrayList();
    //boolean black = true;
    for (int y=topHeight; y<h; y+=pixelSize) {
      for (int x=0; x<w; x+=pixelSize) {  
          grid.add(new Location(x, y));
        /*if (black) {
          grid.add(new Location(x, y, color(0,0,0), LocationType.AIR));
          black ^= true;
        } else {
          grid.add(new Location(x, y, color(255,255,255), LocationType.AIR));
          black ^= true;
        }*/
      }
      //black ^= true;
    }
    populateGrid();
    /*
    new Wall(50, h/2, 100, 15).render(); 
    
    new Wall(w-50, h/2, 100, 15).render();
    
    new Wall(w/2, topHeight+50, 15, 50).render();
    
    new Wall(w/2, h-50, 15, 50).render();
    */
    this.gridCache = new ArrayList();
    this.doFullRender = true; // Why does this variable save as true in this method, but not when placed into resetGame()?
  }
  
  ArrayList<Location> getGrid() {
    return this.grid; 
  }
  
  Location getLocation(Location loc) {
    return getLocation(loc.getX(), loc.getY()); 
  }
  
  Location getLocation(int x, int y) {
    /* The initial, much slower way of fetching a location from the grid
    println();
    int c = 0;
    for (Location loc : grid) {
      if (loc.equals(new Location(x, y))) {
        println("C="+c);
        break;
      }
      c++;
    }*/
    
    
   try {
      if (x % pixelSize != 0) { return null; }
      
      // Jump directly to index of location
      
      /* PLAN:
      
        Original plan was to do: get (y-1) * getHeight() + x % pixelSize , but this returned numbers that were far too high (and threw index out of bounds exceptions). Thus, I returned to the planning
        phase, this time using a set of test coordinates: 
      
        [example coords]
      
        x = 15
        y = 55
        
        c=123 [the actual index as done the slow way]
        
        55 - 50 = 5 [mistake was that I forgot to divide y - top by 5, and thus I was getting absurdly high values for my calculated "y" in grid
        
        (width / 5) * ((y - top) / 5) + x / 5
        
        New problem: Bike wraps around the edge when it collides [still ends the player's game, but this needs fixing]
        Solution: Just add an if statement checking if the Y changed without the player going up/down (see Player.pde -> checkCrash())

      */
      
      int index = (width / pixelSize) * ((y - topHeight) / pixelSize) + x / pixelSize; // A faster way to get the index of a location
      //println("D="+index);
      return grid.get(index);
    } catch (IndexOutOfBoundsException e) {
      //e.printStackTrace(); // An exception should be thrown for debugging purposes 
    }
    
    return null;
  }
  
  void render() {
    
    /*
      gridCache is a much more efficient way of rendering the grid -- instead of iterating every single location with each render(),
      it only draws the locations which have changed, cutting down on lag.
    */
    
    
    
    
    ArrayList<Location> queue = gridCache;
    
    if (doFullRender) { // On the first render it should draw the entire grid
        queue = grid;
        doFullRender = false;
    }
    
    for (Location loc : queue) {
      color c = loc.getColor();
      stroke(c);
      fill(c);
      
      rect(loc.getX(), loc.getY(), pixelSize-1, pixelSize-1);
    }
    
    gridCache = new ArrayList();
    
    /*for (Location loc : grid) {
      color c = loc.getColor();
      stroke(c);
      fill(c);
      
      rect(loc.getX(), loc.getY(), pixelSize, pixelSize);
    }*/
  }
  
  // Error: why doesnt it always log my key press?
  void keyPressed() {
    for (Player player : players) {
      if (player.isKey(key)) {
        player.changeDirection(key);
      }
    }
  }
  
  void draw() {
    if (!runGame) { return; }
    if (doLeaderboard) {
      String gameOver = "Game Over";
      String leaderboard = "";
    
      int place = 1;
      for (Player player : getLeaderboard()) {
        leaderboard += "\n"+(place++)+". "+player.name()+" ("+player.lives()+" lives)";
      }
      
      background(0,0,0);
      PFont f2 = createFont("HelveticaNeue-Bold", 85, true);
      textAlign(CENTER);
      textFont(f2);
      fill(color(134, 244, 250));
      text(gameOver, width/2, height/2);
      
      textFont(f);
      text(leaderboard, width/2, height/2 + 15); // Make text size a variable
      textAlign(BASELINE);
      this.doLeaderboard = false;
      this.runGame = false;
      
      // Need a way to keep this text on the screen without it getting overwritten by setup();
      // Source for below code: https://stackoverflow.com/questions/2258066/java-run-a-function-after-a-specific-number-of-seconds
      new java.util.Timer().schedule( 
      new java.util.TimerTask() {
          @Override
          public void run() {
            setup();
            this.cancel();
          }
      }, 2000);
      
    } else if (this.doRespawn) {
      if (respawnTimer > 0) {
        background(0,0,0);
        textFont(f, 60);
        fill(color(134, 244, 250));
        DecimalFormat df = new DecimalFormat("0.0");
        textAlign(CENTER);
        text("Restarting In\n"+df.format(respawnTimer), width/2, height/2);
        textAlign(BASELINE);
        respawnTimer -= 0.1;
      } else {
        respawnTimer = respawnTimerBackup;
        this.resetGrid();
        int count = 0;
        
        int index = 0;
        for (int i=players.size()-1; i>=0; i--) {
          Player player = players.get(i);
          if (player.lives() > 0) {
            String dir = directions.get(index++); // just assume # players <= # of directions
            player.respawn(spawns.get(dir));
            player.setDirection(dir);
            count++;
          }
        }
        
        if (count <= 1) {
          gameOver();
          return;
        }
        
        this.doRespawn = false;
        frameRate(framerate);
        return;
      }
      
    } else {
      int dead = 0;
      int eliminated = 0;
    
      // Draw the current screen
      for (Player player : players) {
        if (player.isAlive()) {
         player.move(); // This will end up with a problem where if two players run into 
                        // eachother at same time, the player at index 0 with die first. 
        } else {
          dead++;
          // NEED SOME SORT OF "FREEZE FRAME" when everyone dies before switching to timer.
          if (player.lives() == 0) { eliminated++; }
        }
      }
      
      if (players.size() - dead <= 1) {
        //delay(1000); // Pause frame for 1 second
        if (eliminated >= players.size() - 1) { // Can probably merge the two calls to setup()
          // RETURN TO MENU / PLAY AGAIN SCREEN
          gameOver();
          return;
        }
        frameRate(10);
        doRespawn = true;
      } else {
        render();
      }
      
    }
    
    bar.render();
}