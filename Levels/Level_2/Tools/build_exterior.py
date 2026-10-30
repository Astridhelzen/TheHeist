from pathlib import Path
import re
r=[];n=['[node name="BankExterior" type="Node3D"]'];i=0
def v(a):return 'Vector3('+', '.join(map(str,a))+')'
def mat(id,c):r.append(f'[sub_resource type="StandardMaterial3D" id="{id}"]\nalbedo_color = Color({c}, 1)\nroughness = 0.88\n')
for id,c in [('Paving','.46,.48,.49'),('Road','.10,.12,.15'),('Stone','.52,.40,.28'),('Roof','.17,.20,.24'),('Blue','.25,.36,.43'),('Brick','.45,.25,.19'),('Cream','.64,.58,.44'),('Glass','.18,.31,.38'),('White','.8,.79,.69'),('Green','.19,.33,.17'),('Trunk','.24,.15,.09'),('Steel','.1,.12,.13')]:mat(id,c)
def box(name,pos,size,m,collision=True):
 global i
 i+=1;key=str(i)
 r.append(f'[sub_resource type="BoxMesh" id="M{key}"]\nsize = {v(size)}\nmaterial = SubResource("{m}")\n')
 n.append(f'[node name="{name}" type="MeshInstance3D" parent="."]\nposition = {v(pos)}\nmesh = SubResource("M{key}")\n')
 if collision:
  r.append(f'[sub_resource type="BoxShape3D" id="S{key}"]\nsize = {v(size)}\n')
  n.extend([f'[node name="Body" type="StaticBody3D" parent="{name}"]',f'[node name="Shape" type="CollisionShape3D" parent="{name}/Body"]\nshape = SubResource("S{key}")'])
box('StreetGround',(45.148,5.65,5),(43.704,.5,100),'Road')
box('BankPavement',(26.148,5.85,5),(5.704,.3,100),'Paving')
box('FarPavement',(43,5.85,5),(8,.3,100),'Paving')
box('EntryThreshold',(23.17,5.8274,21.36),(.6,.08,2.65),'Paving')
box('NorthBankPavement',(20.746,5.85,-13.85),(5.1,.3,62.3),'Paving')
box('SouthBankPavement',(20.746,5.85,45),(5.1,.3,20),'Paving')
for z in range(-42,53,6):box('RoadMark'+str(z),(34,5.91,z),(.14,.015,2.7),'White',False)
for index,(z,h,m) in enumerate([(-34,13,'Brick'),(-16,18,'Cream'),(3,11,'Blue'),(23,16,'Brick'),(43,12,'Cream')]):
 x=53
 box(f'Building{index}',(x,6+h/2,z),(12,h,15),m)
 box(f'Roof{index}',(x,6+h,z),(12.5,.35,15.5),'Roof')
 box(f'Plinth{index}',(46.9,6.55,z),(.25,1.1,15),'Stone')
 for floor in range(int(h/3)):
  for col in range(4):box(f'Window{index}_{floor}_{col}',(46.94,8+floor*3,z-5.2+col*3.5),(.04,1.5,1.7),'Glass',False)
 box(f'HouseDoor{index}',(46.8,7.3,z),(.15,2.6,1.4),'Roof')
for j,z in enumerate([-35,-17,1,33,48]):
 box(f'Planter{j}',(26,6.2,z),(1.8,.4,1.8),'Stone')
 box(f'TreeTrunk{j}',(26,7.45,z),(.28,2.5,.28),'Trunk')
 box(f'TreeCrown{j}',(26,9.2,z),(2.5,2.4,2.3),'Green',False)
 box(f'LampPost{j}',(28.3,8.1,z+3),(.12,4.2,.12),'Steel')
 box(f'LampHead{j}',(28.3,10.25,z+3),(.6,.2,.6),'White',False)
for j,z in enumerate([-8,39]):
 box(f'BenchSeat{j}',(24,6.5,z),(.7,.13,2.3),'Trunk')
 box(f'BenchBack{j}',(23.65,7,z),(.12,.9,2.3),'Trunk')
 for a in [-.8,.8]:box(f'BenchLeg{j}_{a}',(24,6.25,z+a),(.5,.5,.09),'Steel')
# Bilen markerar flyktplatsen.
box('GetawayBody',(31,6.6,31),(2,.8,4),'Blue')
box('GetawayCabin',(31,7.25,31),(1.8,.65,2.2),'Glass')
for x in [29.98,32.02]:
 for z in [29.7,32.3]:box('Wheel'+str(x)+str(z),(x,6.35,z),(.2,.65,.65),'Steel')
# Avgränsa gatan med byggnader och ändväggar.
box('NorthBlock',(44,11,-46),(46,10,2),'Brick')
box('SouthBlock',(44,11,56),(46,10,2),'Cream')
box('EastBoundary',(66,10,5),(1,8,100),'Stone')
n.append('[node name="Daylight" type="DirectionalLight3D" parent="."]\nrotation_degrees = Vector3(-48, -30, 0)\nlight_color = Color(1, 0.91, 0.79, 1)\nlight_energy = 0.65\nshadow_enabled = true\ndirectional_shadow_max_distance = 100\n')
r.append('[sub_resource type="ProceduralSkyMaterial" id="SkyMaterial"]\nsky_top_color = Color(0.22, 0.38, 0.57, 1)\nsky_horizon_color = Color(0.73, 0.79, 0.82, 1)\n')
r.append('[sub_resource type="Sky" id="Sky"]\nsky_material = SubResource("SkyMaterial")\n')
r.append('[sub_resource type="Environment" id="Environment"]\nbackground_mode = 2\nsky = SubResource("Sky")\nambient_light_source = 3\nambient_light_color = Color(0.7, 0.77, 0.85, 1)\nambient_light_energy = 0.3\ntonemap_mode = 2\n')
n.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]\nenvironment = SubResource("Environment")\n')
Path('Levels/Level_2/BankExterior.tscn').write_text(re.sub(r'(?<![0-9])\.(?=[0-9])', '0.', '[gd_scene format=3]\n\n'+'\n'.join(r+n)+'\n'),encoding='utf-8')
