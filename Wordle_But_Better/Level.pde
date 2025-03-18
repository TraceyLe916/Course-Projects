class Level {
  Wordle word;
  Bow bow;
  Bubble bubbles;
  Life life;
  PImage caution;
  Sound sound;

  int letters_correct = 0;
  int total_bubbles = 5;
  int current_letter = 0;

  ArrayList<Bubble> b;
  Float[] bubbles_start_x;
  Float[] bubbles_start_y;
  int bubble_speed = 3;
  Bubble[] bubble_spawn;
  PImage heartImage;
  PImage streakImage;
  int increment = 0;
  
  boolean level_active = true;

  Collision collision;

  Level() {
    word = new Wordle();
    b = new ArrayList<Bubble>();

    collision = new Collision();
    sound = new Sound();
    bow = new Bow (width/2, height*0.8, 150);
    life = new Life(5); // Assuming 5 lives initially
    heartImage = loadImage("images/heart.png");
    streakImage = loadImage("images/streak.png");
    bubble_spawn = new Bubble[6];
    caution = loadImage("images/WBB_caution_tape.png");

    bubbles_start_x = new Float[2];
    bubbles_start_y = new Float[2];
    float offscreen_right = -40;
    float offscreen_left = width + 40;
    float offscreen_up = -40;
    float offscreen_bottom = (height * .7 + 40);

    bubbles_start_x[0] = offscreen_right;
    bubbles_start_x[1] = offscreen_left;
    bubbles_start_y[0] = offscreen_up;
    bubbles_start_y[1] = offscreen_bottom;

    bubble_spawn[0] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], height * 0.65 - 40, bubble_speed);
    bubble_spawn[1] = new Bubble(word.word_array[int(random(0, 5))], 500, bubbles_start_y[int(random(0, 2))], bubble_speed);
    bubble_spawn[2] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], 150, bubble_speed);
    bubble_spawn[3] = new Bubble(word.word_array[int(random(0, 5))], 200, bubbles_start_y[int(random(0, 2))], bubble_speed);
    bubble_spawn[4] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], 300, bubble_speed);


    for (int i = 0; i < total_bubbles; i++) {
      b.add(bubble_spawn[i]);
    }
  }

  void display_arrow_info() {
  // displays whether an arrow is on kill or add mode
    fill(25, 248, 255);
    rect(1000, 730, 150, 80);
    fill(0);
    textSize(14);
    text("ARROW MODE:", 1000, 710);
    textSize(24);
    if (bow.arrow.mode == 0) {
      text("ADD", 1000, 740);
    } else if (bow.arrow.mode == 1) {
      fill(255, 0, 0);
      text("KILL", 1000, 740);
    }
  }


  void display_bubbles() {
    for (Bubble bub : b) {
      bub.display();
      bub.move();
    }
  }

  void update_bubbles() {
  // creates new bubbles when one goes out of bounds
    for (Bubble bub : b) {
      if (bub.checkOutOfBounds()) {
        int kill_index = b.indexOf(bub);
        b.remove(kill_index);
        
        // 6 possible respawn locations
        bubble_spawn[0] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], height * 0.65 - 40, bubble_speed);
        bubble_spawn[1] = new Bubble(word.word_array[int(random(0, 5))], 500, bubbles_start_y[int(random(0, 2))], bubble_speed);
        bubble_spawn[2] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], 100, bubble_speed);
        bubble_spawn[3] = new Bubble(word.word_array[int(random(0, 5))], 200, bubbles_start_y[int(random(0, 2))], bubble_speed);
        bubble_spawn[4] = new Bubble(word.word_array[int(random(0, 5))], bubbles_start_x[int(random(0, 2))], 300, bubble_speed);
        bubble_spawn[5] = new Bubble(word.word_array[int(random(0, 5))], 800, bubbles_start_y[int(random(0, 2))], bubble_speed);
       
        // minimizes collision upon respawning
        b.add(bubble_spawn[increment]);
        
        if (increment < 5) {
          increment += 1;
        } else {
          increment = 0;
        }
        break;
      }
    }
  }

  void checkCollision() {
    collision.findCollision(b, bow);
    if (collision.hasArrCollision()) {
      update_array(collision.letter);
      collision.resetArr();
      sound.bubble_pop();
    }
  }


  void lives_update() {
    if (collision.hasBubCollision()) {
      collision.resetBub();
      life.loseLife();
      sound.bubble_pop();
    }
  }

  boolean checkWinCondition() {
    if (letters_correct == word.current_word.length()) {
      return true;
    }
    return false;
  }

  boolean checkLoseCondition() {
    if (life.getCurrentLives() <= 0) {
      return true;
    }
    return false;
  }


  void display_boxes() {
    // displays blank wordle boxes
    rectMode(CORNER);
    noStroke();
    fill(0, 0, 0, 95);
    rect(0, height * 0.7, width, height);
    rectMode(CENTER);
    for (int i = 0; i < 5; i++) {
      fill(25, 248, 255);
      rect((20 * 3.5 * i) + 50, height - 50, 50, 50);
    }
  }

  void display_word() {
    textAlign(CENTER, CENTER);
    fill(0);
    image(caution, 0, height * 0.7 + 30, width, 30);
    image(caution, 0, height * 0.7 - 10, width, 10);
    fill(0);
    
    // displays the wordle letters according to how many were crrect
    if (letters_correct >= 1) {
      text(word.word_array[0], (20 * 3.5 * 0) + 50, height - 50);
    }
    if (letters_correct >= 2) {
      text(word.word_array[1], (20 * 3.5 * 1) + 50, height - 50);
    }
    if (letters_correct >= 3) {
      text(word.word_array[2], (20 * 3.5 * 2) + 50, height - 50);
    }
    if (letters_correct >= 4) {
      text(word.word_array[3], (20 * 3.5 * 3) + 50, height - 50);
    }
    if (letters_correct == 5) {
      text(word.word_array[4], (20 * 3.5 * 4) + 50, height - 50);
    }
  }

  void display_hint() {
    // displays grayed out wordle word for easy mode only
    fill(color(76, 206, 222));
    textAlign(CENTER, CENTER);
    text(word.word_array[0], (20 * 3.5 * 0) + 50, height - 50);
    text(word.word_array[1], (20 * 3.5 * 1) + 50, height - 50);
    text(word.word_array[2], (20 * 3.5 * 2) + 50, height - 50);
    text(word.word_array[3], (20 * 3.5 * 3) + 50, height - 50);
    text(word.word_array[4], (20 * 3.5 * 4) + 50, height - 50);
  }

  boolean letter_checker(char letter_hit) {
    return letter_hit == word.word_array[current_letter];
  }

  void update_array(char letter_hit) {
  // checks whether the letter hit was the correct letter at the correct position in the char array
    if (letter_checker(letter_hit) && bow.arrow.mode == 0) {
      sound.correct_bubble();
      letters_correct += 1;
      current_letter += 1;
    } else if (letter_hit != word.word_array[current_letter] && bow.arrow.mode == 0) {
      sound.wrong_bubble();
      life.loseLife();
    }
  }

  void displayStats(int streak) {
    // Draw heart icons to represent lives
    float heartSize = 30;
    float heartSpacing = 7; // Spacing between heart icons
    float startX = 40;
    float y = 40; // Fixed y-coordinate for drawing heart icons

    for (int i = 0; i < life.getCurrentLives(); i++) {
      image(heartImage, startX + i * (heartSize + heartSpacing), y, heartSize, heartSize);
    }

    // Draw streak icon and display streak number
    float streakSize = 30;
    float streakX = 35;
    float streakY = y + 40;

    // Draw streak icon
    image(streakImage, streakX, streakY, streakSize, streakSize);

    // Display streak number to the right of the streak icon
    fill(255);
    textSize(20);
    textAlign(LEFT, CENTER); // Align text to the left
    text(streak, streakX + 30, streakY + 15);
  }
}
