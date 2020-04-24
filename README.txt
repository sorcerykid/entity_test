Entity Test Mod
By Leslie Krause
----------------------------------------------

I developed this mod for interactively testing additional API methods and callbacks for 
LuaEntitySAOs. I recommend using it with the Minimal Development Test, since it expects a 
singlenode mapgen.

In order to use this mod, you will need to compile Minetest with the following patch:
https://github.com/sorcerykid/minetest/tree/extend-entity-api

After joining the game, type `/add` into chat to spawn a new entity. Then type `/cmd` to 
choose from a battery of preset test scripts. You can also write your own test scripts and 
execute them under the "(Custom)" preset.

Statements in a script can be one of the following:

 * wait <time>: <expr>
   Calls the given ObjectRef method, <expr> after the given delay, <time>

 * now: <expr>
   Calls the given ObjectRef method, <expr>, immediately

Alternatively, you can call an ObjectRef method directly by typing `/cmd <expr>` into chat.

To defer execution of a method until the `on_step()` callback, simply prepend <expr> with
an ampersand as in `/cmd @set_velocity(vec(1,0,1))`. This can prove useful for testing the
possibility of side-effects that may not be revealed otherwise.

All test scripts are executed within a sandbox so that most errors can be trapped without 
crashing Minetest. Several global variables are provided for convenience when testing:

 * `pi` = math.pi,
 * `inf` = math.huge,
 * `nan` = 0/0,
 * `vec` = vector.new,
 * `home` = {x = 0, y = 5, z = 0}
 * `none` = {x = 0, y = 0, z = 0}
 * `rad360` = 2 * math.pi,
 * `rad180` = math.pi,
 * `rad90` = math.pi / 2,
 * `rad60` = math.pi / 3,
 * `rad45` = math.pi / 4,
 * `rad30` = math.pi / 6,
 * `rad20` = math.pi / 9,

If you have spawned multiple entities, then you can select which entity to monitor and 
control either by punching it or typing `/sel` and the respective object ID. To despawn an 
entity, simply select it and type `/cmd remove()`.


Source Code License
----------------------

GNU Lesser General Public License v3 (LGPL-3.0)

Copyright (c) 2020, Leslie E. Krause

This program is free software; you can redistribute it and/or modify it under the terms of
the GNU Lesser General Public License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

http://www.gnu.org/licenses/lgpl-2.1.html


Multimedia License (textures, sounds, and models)
----------------------------------------------------------

Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)

   /models/reindeer.b3d
   by GreenDimond
   obtained from https://forum.minetest.net/viewtopic.php?t=18958

   /models/paniki.b3d
   by Lean Rada
   obtained from https://forum.minetest.net/viewtopic.php?f=50&t=11030

   /textures/mobs_reindeer.png
   by GreenDimond
   obtained from https://forum.minetest.net/viewtopic.php?t=18958

   /textures/mobs_paniki.png
   by Lean Rada
   obtained from https://forum.minetest.net/viewtopic.php?f=50&t=11030

You are free to:
Share — copy and redistribute the material in any medium or format.
Adapt — remix, transform, and build upon the material for any purpose, even commercially.
The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:

Attribution — You must give appropriate credit, provide a link to the license, and
indicate if changes were made. You may do so in any reasonable manner, but not in any way
that suggests the licensor endorses you or your use.

No additional restrictions — You may not apply legal terms or technological measures that
legally restrict others from doing anything the license permits.

Notices:

You do not have to comply with the license for elements of the material in the public
domain or where your use is permitted by an applicable exception or limitation.
No warranties are given. The license may not give you all of the permissions necessary
for your intended use. For example, other rights such as publicity, privacy, or moral
rights may limit how you use the material.

For more details:
http://creativecommons.org/licenses/by-sa/3.0/
