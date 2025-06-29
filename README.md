# FakeDatastore
A tool to emulate DataStoreService on older ROBLOX clients and custom launchers (e.g. Novetus, ORRH and RBLXHUB).
# Installation
*Note: This assumes you've installed nodejs. If you haven't, go to https://nodejs.org and install it.*  
The installation steps for FakeDatastore are rather simple.  
- Open your terminal.
- Run `git clone https://github.com/tocatwastaken/FakeDatastore.git`
- Once done, do `cd FakeDatastore`
- Run `npm install`
- Then, do `npm start`
- Just like that, it should work.
# Usage
To use the provided ModuleScript, do the following:
 - Import it into ROBLOX studio.
 - Put it somewhere your script can access.
 - Do `require(path.to.the.script)` in place of `game:GetService("DataStoreService")`
 - Just like that, it should work!
