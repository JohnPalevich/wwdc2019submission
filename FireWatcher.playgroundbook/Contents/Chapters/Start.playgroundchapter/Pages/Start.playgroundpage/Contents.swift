//#-hidden-code
import PlaygroundSupport
let viewController = ViewController()
//#-end-hidden-code
/*:
 # Welcome to Firewatcher
 
 - Author: John Palevich
 
 You have taken a job as a fire watcher at a famous national park.
 
 Your job is to make sure the forest is safe.
 
 ## Setup
 
 1. Hold your iPad upright and tap on the "Run My Code" button.
 
 2. Once the camera is running, bring the iPad's camera close to a flat horizontal surface,
 such as a table or floor.
 
 3. Move the camera back and forth until the forest appears.

 ## Gameplay
 
 During your watch, fires will randomly start.

 To put them out, tap on the tree that is on fire.
 
 If you let the fire burn for too long, it will spread to nearby trees. If a tree is on fire for too long, it will die.
 
 If you would like to adjust number of trees in a column and row, the time it takes to randomly ignite a tree, change the time it takes to have a fire spread, or enter hard mode, scroll down.
 
 # Make sure to play with the sound on!
 */
// Adjust numTrees to change the number of trees in a column and row.
viewController.numTrees = 20
// Adjust ignitionPeriod to change the number of seconds between random tree ignitions.
viewController.ignitionPeriod = 5
// Changing spreadPeriod changes the number of seconds before the fire spreads.
viewController.spreadPeriod = 15
// Enter Hard Mode Here
//: [Go To Hard Mode](@next)
//#-hidden-code
PlaygroundPage.current.liveView = viewController
//#-end-hidden-code
