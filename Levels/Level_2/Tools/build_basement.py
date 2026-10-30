"""Generate the editable Godot basement; coordinates relative to the existing stair foot."""
from pathlib import Path
import math
res=[];nodes=['[node name="BasementVault" type="Node3D"]'];seq=0
def vec(v):return 'Vector3('+', '.join(str(x) for x in v)+')'
def mat(name,color,metal=0,emission=False):
 s=f'[sub_resource type="StandardMaterial3D" id="{name}"]\nalbedo_color = Color({color}, 1)\nmetallic = {metal}\nroughness = 0.65\n'
 if emission:s+='emission_enabled = true\nemission = Color(0.75, 0.88, 1, 1)\nemission_energy_multiplier = 2.0\n'
 res.append(s)
def box(name,pos,size,material,collision=True,parent='.'):
 global seq
 seq+=1;rid=str(seq);res.append(f'[sub_resource type="BoxMesh" id="Mesh{rid}"]\nsize = {vec(size)}\nmaterial = SubResource("{material}")\n')
 nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\nposition = {vec(pos)}\nmesh = SubResource("Mesh{rid}")\n')
 path=name if parent=='.' else parent+'/'+name
 if collision:
  res.append(f'[sub_resource type="BoxShape3D" id="Shape{rid}"]\nsize = {vec(size)}\n')
  nodes.append(f'[node name="Body" type="StaticBody3D" parent="{path}"]\n')
  nodes.append(f'[node name="Collision" type="CollisionShape3D" parent="{path}/Body"]\nshape = SubResource("Shape{rid}")\n')
mat('Concrete','0.30, 0.32, 0.34');mat('Floor','0.16, 0.18, 0.20');mat('Steel','0.35, 0.40, 0.44',.75);mat('DarkSteel','0.08, 0.10, 0.12',.7);mat('Gold','0.85, 0.57, 0.15',.7);mat('Light','0.8, 0.9, 1',0,True)
for name,z,width,length in [('Landing',-2,8,4),('Corridor',-8,6,8),('Vault',-17,10,10)]:
 box(name+'Floor',(0,-.15,z),(width,.3,length),'Floor')
 box(name+'Ceiling',(0,3.65,z),(width,.3,length),'Concrete')
 for side in [-1,1]:box(name+('LeftWall' if side<0 else 'RightWall'),(side*(width/2+.15),1.75,z),(.3,3.5,length),'Concrete')
 # Gul kant längs golvet.
 for side in [-1,1]:box(name+('LeftTrim' if side<0 else 'RightTrim'),(side*(width/2-.035),.15,z),(.06,.12,length),'Steel',False)
for side in [-1,1]:box('LandingEnd'+str(side),(side*3.5,1.75,-4),(1,3.5,.3),'Concrete')
box('VaultBackWall',(0,1.75,-22),(10.6,3.5,.3),'Concrete')
# Dörröppning: 2,6 m bred och 2,85 m hög.
for side in [-1,1]:
 box('VaultFront'+str(side),(side*3.15,1.75,-12),(3.7,3.5,.5),'Concrete')
 box('DoorFrame'+str(side),(side*1.38,1.48,-11.97),(.16,2.96,.65),'Steel')
box('VaultLintel',(0,3.18,-12),(2.6,.64,.5),'Concrete');box('DoorFrameTop',(0,2.92,-11.97),(2.92,.16,.65),'Steel')
nodes.append('[node name="VaultDoor" parent="." instance=ExtResource("1_door")]\nposition = Vector3(-1.25, 0, -12)\nrotation = Vector3(0, 0, 0)\n')
# Dörrdelarna följer gångjärnet. Kortskriptet bygger kollisionen.
box('ReinforcedDoor',(1.25,1.43,0),(2.5,2.8,.42),'DarkSteel',False,'VaultDoor')
def cylinder(name,pos,radius,depth,material,parent='VaultDoor'):
 global seq
 seq+=1;rid=str(seq)
 res.append(f'[sub_resource type="CylinderMesh" id="Mesh{rid}"]\ntop_radius = {radius}\nbottom_radius = {radius}\nheight = {depth}\nradial_segments = 48\nmaterial = SubResource("{material}")\n')
 nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\nposition = {vec(pos)}\nrotation = Vector3(1.5707963, 0, 0)\nmesh = SubResource("Mesh{rid}")\n')
cylinder('ArmouredRim',(1.25,1.43,.25),1.17,.2,'Steel')
cylinder('RecessedPlate',(1.25,1.43,.36),1.03,.06,'DarkSteel')
cylinder('InnerSteelPlate',(1.25,1.43,.40),.88,.06,'Steel')
for i in range(12):
 angle=i*math.tau/12
 cylinder('RimBolt'+str(i),(1.25+1.10*math.cos(angle),1.43+1.10*math.sin(angle),.38),.055,.075,'Gold')
for y in [.5,1.43,2.35]:
 box('LockBolt'+str(y),(2.43,y,.04),(.38,.16,.3),'Steel',False,'VaultDoor')
 box('HeavyHinge'+str(y),(.04,y,.03),(.24,.3,.5),'Steel',False,'VaultDoor')
# Behåll dörrhjulet framför den nya ytan.
nodes.append('[node name="Wheel" type="Node3D" parent="VaultDoor"]\nposition = Vector3(1.25, 1.43, 0.53)\n')
cylinder('WheelHub',(0,0,.0),.13,.18,'Gold','VaultDoor/Wheel')
for i in range(6):
 angle=i*math.tau/6
 box('Spoke'+str(i),(.25*math.cos(angle),.25*math.sin(angle),0),(.55,.065,.08),'Gold',False,'VaultDoor/Wheel')
 nodes[-1]+=f'rotation = Vector3(0, 0, {angle})\n'
for side in [-1,1]:
 box('StairSide'+str(side),(side*4.15,4.25,4.15),(.3,8.5,8.6),'Concrete')
box('StairBackWall',(0,2.4,8.45),(8.6,5.0,.3),'Concrete')
box('StairUnderfloor',(0,-.15,4.25),(8,.3,8.3),'Floor')
# Täck grunden bredvid trappan utan att blockera passagen.
for side in [-1,1]:
 box('FoundationWing'+str(side),(side*15,2.4,-4.05),(26,5.0,.4),'Concrete')
 box('FoundationReturn'+str(side),(side*28,2.4,2.15),(.4,5.0,12.8),'Concrete')
 box('FoundationRear'+str(side),(side*16,2.4,8.45),(24,5.0,.4),'Concrete')
 box('BankFloorInfill'+str(side),(side*16,4.85,4.15),(24,.3,8.6),'Floor')
box('CardPedestal',(-2.8,.5,-2),(1.0,1.0,.65),'DarkSteel')
for side in [-1,1]:
 for column in range(5):
  z=-14-column*1.4
  box(f'SafeCabinet{side}_{column}',(side*4.65,1.3,z),(.55,2.6,1.25),'DarkSteel')
  for row in range(5):
   box(f'DepositBox{side}_{column}_{row}',(side*4.34,.3+row*.49,z),(.05,.43,1.14),'Steel',False)
   box(f'Handle{side}_{column}_{row}',(side*4.29,.3+row*.49,z),(.05,.055,.24),'DarkSteel',False)
box('CountingTable',(0,.85,-18),(2.4,.15,1.5),'Steel')
for x in [-1,1]:
 for z in [-18.55,-17.45]:box('TableLeg'+str(x)+str(z),(x,.4,z),(.1,.8,.1),'DarkSteel')
# Level2.tscn placerar bytet på bordet.
for i,z in enumerate([-2,-7,-10,-15,-20]):
 box('CeilingFixture'+str(i),(0,3.43,z),(1.8,.12,.4),'DarkSteel',False)
 box('LightPanel'+str(i),(0,3.35,z),(1.6,.035,.3),'Light',False)
 nodes.append(f'[node name="Light{i}" type="OmniLight3D" parent="."]\nposition = Vector3(0, 2.9, {z})\nlight_color = Color(0.83, 0.9, 1, 1)\nlight_energy = 1.3\nomni_range = 6.0\nshadow_enabled = true\n')
nodes.append('[node name="VaultSign" type="Label3D" parent="."]\nposition = Vector3(0, 3.17, -11.7)\ntext = "VAULT  /  B2"\nfont_size = 64\npixel_size = 0.006\n')
nodes.append('[node name="Arrival" type="Marker3D" parent="."]\nposition = Vector3(0, 0.1, -1.5)\n')
# Osynlig ramp under trappan.
points=[(x,y,z) for x in [-3.75,3.75] for y,z in [(-.2,-.45),(.015,-.45),(4.8,7.2),(5.115,7.2)]]
res.append('[sub_resource type="ConvexPolygonShape3D" id="StairRamp"]\npoints = PackedVector3Array('+', '.join(str(c) for p in points for c in p)+')\n')
res.append('[sub_resource type="BoxShape3D" id="StairTopLanding"]\nsize = Vector3(7.5, 0.2, 1.1)\n')
nodes.extend(['[node name="StairCollision" type="StaticBody3D" parent="."]','[node name="Shape" type="CollisionShape3D" parent="StairCollision"]\nshape = SubResource("StairRamp")'])
nodes.append('[node name="TopLanding" type="CollisionShape3D" parent="StairCollision"]\nposition = Vector3(0, 5.015, 7.75)\nshape = SubResource("StairTopLanding")')
nodes.append('[node name="AccessCard" parent="." instance=ExtResource("2_access")]')
text='[gd_scene format=3]\n\n[ext_resource type="PackedScene" path="res://Levels/Level_2/Assets/Vault_Door_Level1.glb" id="1_door"]\n[ext_resource type="PackedScene" path="res://Levels/Level_2/VaultAccess.tscn" id="2_access"]\n\n'+'\n'.join(res+nodes)+'\n'
Path('Levels/Level_2/BasementVault.tscn').write_text(text,encoding='utf-8')
print('Generated basement with',seq,'mesh parts')



