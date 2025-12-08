# Contributing

So you want to help out? Cool. Here is the deal.

## Result
I split `main.lua` into `modules/` because scrolling through 800 lines of spaghetti code was making me sad.

- **main.lua**: The boss. It just loads the other guys.
- **modules/**: Where the actual work happens.
    - `backend.lua`: The heavy lifter. File I/O and data crunching.
    - `menus.lua`: Draws the boxes you tap on. Basically the gui.
    - `profiles.lua`: Remembers your setups so you don't have to.
    - `search.lua`: Finds things. Shocking, I know.
    - `constants.lua`: `protected_items` live here. **Do not** remove items from this list unless you are prepared for the consequences.

## How to Help
1.  Break things, then fix them.
2.  Add a feature, then make sure it doesn't break existing things.
3.  Keep it clean. No massive functions.

## Pull Requests
Send them over. If it works and doesn't look like a crime scene, I'll probably merge it.
