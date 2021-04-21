# Auto-Mario
A pair of Lua scripts for use in Bizhawk that can play Super Mario Bros. based on sample gameplay from a human.

Walkthrough of the files:
* 1-1 start.State:
	* A savestate that MarioRun.lua uses to start at the beginning of the first level.
* Input Log.txt:
	* The input log that I extracted from the "mario input 2.bk2" movie file. When you open the movie file in a program like 7-zip, you can see an Input Log just like this one and extract it. Once extracted, place it in the Bizhawk/Lua folder.
* MarioPlayback.lua:
	* After running MarioRun.lua, you should have a number of .save files. These are pre-processed input logs for playing back the same gameplay from the starting state, a.k.a. a hand-coded version of playing back a Bizhawk movie.
	* Open the script and edit the value of "save_file" to match the name of the save you are playing back.
* MarioRun.lua:
	* This script will start from the savestate and try to play through the game as far as it can.
	* It uses input samples from the Input Log (which contains inputs from a human player), slices them into 10-frame pieces, then tries random combinations and picks the one that gives it the most reward.
	* While this is not machine learning, it does demonstrate how effective a reward function can be for evaulating gameplay. In other words, it gives me proof that a reward function coded this way can work for a ML algorithm.
	* Once it gets stuck or you get bored, simply stop running the script and set up MarioPlayback.lua to see the resulting gameplay.
* mario input2.bk2:
	* This is a Bizhawk movie that I recorded through the File > Movie > Record Movie menu. If you want to use your own input samples, start yourself at the beginning of a level, then record yourself playing the game for a bit. When you're done, pause the emulator and stop recording. Save the movie file, open it in 7-zip, and extract Input Log.txt to your Bizhawk/Lua folder. MarioRun.lua will then automatically read the file and use the input samples to play the game.
* save 37.save:
	* An example .save file, which contains all the inputs that MarioRun.lua produced while playing the game. You can test MarioPlayback.lua using this file. Simply place it in the Bizhawk/Lua folder with everything else.
