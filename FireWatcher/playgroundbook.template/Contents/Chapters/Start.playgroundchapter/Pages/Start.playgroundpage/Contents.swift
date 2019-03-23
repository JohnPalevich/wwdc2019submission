
//#-hidden-code
import PlaygroundSupport
let viewController = ViewController()
//#-end-hidden-code


/*:
 # Welcome to Firewatcher
 
 - Author: John Palevich
 
 You have taken a job as a Fire Watcher at a famous National Park.
 
 Your job is to make sure the forest is safe.
 
 ## Setup
 
 1. Tap on the "Run My Code" button.
 
 2. Point your camera at a flat horizontal surface, such as a table or floor.
 
 3. Move the camera back and forth until the forest appears.

 ## Gameplay
 
 During your watch, fires will randomly start.

 To put them out, tap on the tree that is on fire.
 
 If you let the fire burn for too long, it will spread to nearby trees. If a tree is on fire for more than 10 seconds, it will die.
 
 # Make sure to play with the sound on!
 */

// Adjust numTrees to change the number of trees in a column and row.
viewController.numTrees = 20
// Adjust ignitionPeriod to change the number of seconds between random tree ignitions.
viewController.ignitionPeriod = 5
// Changing spreadPeriod changes the number of seconds before the fire spreads.
viewController.spreadPeriod = 15

//#-hidden-code
PlaygroundPage.current.liveView = viewController
//#-end-hidden-code
