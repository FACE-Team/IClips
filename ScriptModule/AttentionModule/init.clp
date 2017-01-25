(deftemplate MAIN::subject "These are subject's peculiar 
							characteristics detected by F.A.C.E."
   (slot id (type INTEGER) (default ?DERIVE))
   (slot idKinect (type INTEGER) (default ?DERIVE))
   (slot trackedState (type SYMBOL) (default False) (allowed-symbols False True))
   (multislot name (type LEXEME) (default unknown))
   (slot gender (type SYMBOL) (default unknown) (allowed-symbols Male Female unknown))
   (slot age (type INTEGER) (default ?DERIVE))
   (slot speak_prob (type NUMBER) (default ?DERIVE) (range 0.0 1.0))
   (slot gesture (type INTEGER) (default 0))
   (slot uptime (type NUMBER) (default ?DERIVE) (range 0.0 ?VARIABLE))
   (slot angle (type NUMBER) (default ?DERIVE))
   
   (slot happiness_ratio (type NUMBER) (default ?DERIVE))
   (slot anger_ratio (type NUMBER) (default ?DERIVE))
   (slot sadness_ratio (type NUMBER) (default ?DERIVE))
   (slot surprise_ratio (type NUMBER) (default ?DERIVE))
   
   (multislot head (type NUMBER) (default ?DERIVE))
   (multislot neck (type NUMBER) (default ?DERIVE))
   (multislot spineShoulder (type NUMBER) (default ?DERIVE))
   (multislot spineBase (type NUMBER) (default ?DERIVE))
   (multislot spineMid (type NUMBER) (default ?DERIVE))
   (multislot shoulderLeft (type NUMBER) (default ?DERIVE))
   (multislot shoulderRight (type NUMBER) (default ?DERIVE))
   (multislot elbowLeft (type NUMBER) (default ?DERIVE))
   (multislot elbowRight (type NUMBER) (default ?DERIVE))
   (multislot wristLeft (type NUMBER) (default ?DERIVE))
   (multislot wristRight (type NUMBER) (default ?DERIVE))
   (multislot handLeft (type NUMBER) (default ?DERIVE))
   (multislot handRight (type NUMBER) (default ?DERIVE))
   (multislot hipLeft (type NUMBER) (default ?DERIVE))
   (multislot hipRight (type NUMBER) (default ?DERIVE))
   (multislot kneeLeft (type NUMBER) (default ?DERIVE))
   (multislot kneeRight (type NUMBER) (default ?DERIVE))
   (multislot ankleLeft (type NUMBER) (default ?DERIVE))
   (multislot ankleRight (type NUMBER) (default ?DERIVE))
   (multislot footLeft (type NUMBER) (default ?DERIVE))
   (multislot footRight (type NUMBER) (default ?DERIVE))
   (multislot handTipLeft (type NUMBER) (default ?DERIVE))
   (multislot handTipRight (type NUMBER) (default ?DERIVE))
   (multislot thumbLeft (type NUMBER) (default ?DERIVE))
   (multislot thumbRight (type NUMBER) (default ?DERIVE))
)

   
(deftemplate MAIN::surroundings "These are surrounding's peculiar 
								 characteristics detected by F.A.C.E."
   (slot soundAngle (type NUMBER) (default ?DERIVE))
   (slot soundEstimatedX (type NUMBER) (default ?DERIVE))
   (multislot recognizedWord (type LEXEME) (default unknown))
   (slot numberSubject (type INTEGER))
   (multislot ambience (type LEXEME))
   (multislot resolution (type NUMBER))
   (multislot saliency (type NUMBER)) ; first two values are x,y in pixels and third one is weight
   (slot toiMic (type NUMBER))
   (slot toiTemp (type NUMBER))
   (slot toiIR (type NUMBER))
   (slot toiTouch (type LEXEME) (default False) (allowed-symbols False True))
   (slot toiLux (type NUMBER))
)

   
(deftemplate MAIN::winner "This is the winner template; inside you can find 
						   ID, point to look and lookrule fired"
   (slot id (type INTEGER) (default 0))
   (multislot point (type NUMBER) (default 0.5 0.5))
   (slot lookrule (type LEXEME) (default none))
)


(deftemplate MAIN::face "This is the robot emotional state template, 
						 containing its current mood and expression"
   (multislot mood (type NUMBER) (default 0.0 0.0))
   (multislot ecs (type NUMBER) (default 0.0 0.0))
)


(deftemplate MAIN::sm "This is the somatic marker template"
   (slot id (type INTEGER) (default 0))
   (slot marker (type INTEGER) (default 0) (allowed-values -1 0 1))
)


(deffunction moodchange "This is the function for changing the mood values
						 without going out from the interval (-1.0 ; 1.0)" 
(?m ?n)
(bind ?newm (+ ?n ?m))
(if (and (> ?newm -1.0) (< ?newm 0)) then (return ?newm))
(if (<= ?newm -1.0) then (return -1.0))
(if (and (> ?newm 0) (< ?newm 1.0)) then (return ?newm))
(if (>= ?newm 1.0) then (return 1.0))
)

(deffunction flatmood "This is the function for changing the mood values
						 bringing them to (0.0 ; 0.0)" 
(?m)
(if (and (> ?m 0.0) (< ?m 0.06)) then (return 0.0))
(if (= ?m 0.0) then (return 0.0))
(if (and (< ?m 0.0) (> ?m -0.06)) then (return 0.0))
(if (< ?m -0.015) then 
					(bind ?newm (+ ?m 0.05))
					(return ?newm))
(if (> ?m 0.015) then 
					(bind ?newm (- ?m 0.05))
					(return ?newm))
)

  
(deffacts MAIN::initialization "Just to initialize some useful facts" 
   (winner)
   (winner_not_chosen)
   (face)
   (tracking_is OFF)
   (sm)
)

   
(defrule MAIN::check_presence "If, at least, one subject is tracked then tracking is on" 
   (surroundings (numberSubject ?numb))
   ?trackOFF <- (tracking_is OFF)
   (test (> ?numb 0))
   =>
   (retract ?trackOFF)
   (assert (tracking_is ON))
)



(defrule MAIN::check_loneliness "If no subject is tracked then tracking is off" 
   (surroundings (numberSubject ?numb))
   (test (eq ?numb 0))
   =>
   (assert (tracking_is OFF))
)
 
  
(defrule MAIN::refresh_loneliness "If you were lonely at the beginning 
								   you will be it also when nobody is inside!"
   ?trackON <- (tracking_is ON)
   (tracking_is OFF)
   =>
   (retract ?trackON)
)
   
   
(defrule MAIN::boring_loneliness "If the robot doesn't see anyone 
								  it's bored and follows the virtual point"
   ?check <- (winner_not_chosen)
   (tracking_is OFF)
   ?surround <- (surroundings (saliency ?x ?y ?) (resolution ?w ?h))
   ?win <- (winner) 
   ?face <- (face (mood ?v ?a))
   =>
   (bind ?nx (/ ?x ?w))
   (bind ?ny (- 1 (/ ?y ?h)))
   (bind ?newv (flatmood ?v))
   (bind ?newa (flatmood ?a))
   (modify ?face (ecs -0.30 -0.45) (mood ?newv ?newa))
   (modify ?win (id 1) (point ?nx ?ny) (lookrule LONELINESS))
   (retract ?surround ?check)
   (assert (winner_is_chosen))
)


(defrule MAIN::lookrule_CrossedArms "This rule selects the winner as the person 
								    who is crossing their arms"
   (declare (salience 1000))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (gesture ?gest) (head ?x ?y ?))
   ?win <- (winner)
   ?face <- (face (mood ?v ?a))
   (test (eq ?gest 4))
   =>
   (bind ?newv (moodchange ?v -0.03))
   (bind ?newa (moodchange ?a 0.03))
   (modify ?face (ecs -0.75 -0.75) (mood ?newv ?newa))
   (modify ?win (id ?id) (point ?x ?y) (lookrule Crossed_Arms))
   (retract ?check) 
   (assert (winner_is_chosen))
)


(defrule MAIN::lookrule_happy "This rule selects the winner as the person 
								   who is laughing or smiling to the robot"
   (declare (salience 1000))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (gesture ?gest) (head ?x ?y ?))
   ?win <- (winner)
   ?face <- (face (mood ?v ?a))
   (test (eq ?gest 1))
   =>
   (bind ?newv (moodchange ?v +0.04))
   (bind ?newa (moodchange ?a -0.03))
   (modify ?face (ecs 0.85 0.10) (mood ?newv ?newa))
   (modify ?win (id ?id) (point ?x ?y) (lookrule HappyLikeU))
   (retract ?check) 
   (assert (winner_is_chosen))
)


(defrule MAIN::lookrule_positive_intrusive "Ehi! You are too close to me... 
									        and I like it!"
   (declare (salience 130))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   (sm (id ?id) (marker 1))
   ?win <- (winner)
   ?face <- (face)
   (test (< ?z 1))
   =>
   (modify ?face (ecs 0.90 0.05))
   (modify ?win (id ?id) (point ?x ?y) (lookrule POSITIVE-INTRUSIVE))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule MAIN::lookrule_negative_intrusive "Ehi! You are too close to me... 
									        and I can't stand it!"
   (declare (salience 130))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   (sm (id ?id) (marker -1))
   ?win <- (winner)
   ?face <- (face)
   (test (< ?z 1))
   =>
   (modify ?face (ecs -0.65 0.35))
   (modify ?win (id ?id) (point ?x ?y) (lookrule NEGATIVE-INTRUSIVE))
   (retract ?check) 
   (assert (winner_is_chosen))
)


(defrule MAIN::lookrule_intrusive "Ehi! You are too close to me..."
   (declare (salience 120))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (< ?z 1))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule INTRUSIVE))
   (retract ?check) 
   (assert (winner_is_chosen))
)




(defrule MAIN::lookrule_distance1 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 110))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (<= ?z 1.5) (>= ?z 1)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance1))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule MAIN::lookrule_distance2 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 105))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (<= ?z 1.65) (> ?z 1.5)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance2))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule MAIN::lookrule_distance3 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 100))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (<= ?z 1.80) (> ?z 1.65)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance3))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule MAIN::lookrule_distance4 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 90))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (< ?z 2) (> ?z 1.80)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance4))
   (retract ?check) 
   (assert (winner_is_chosen))
)


(defrule MAIN::lookrule_distance5 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 80))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (< ?z 2.5) (> ?z 2)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance5))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule MAIN::lookrule_distance6 "This rule selects the winner as the person 
								   who is near to the robot"
   (declare (salience 79))
   ?check <- (winner_not_chosen)
   (tracking_is ON)
   (subject (idKinect ?id) (head ?x ?y ?z))
   ?win <- (winner)
   ?face <- (face)
   (test (and (< ?z 4.5) (> ?z 2.5)))
   =>
   (modify ?face (ecs 0.0 0.0))
   (modify ?win (id ?id) (point ?x ?y) (lookrule distance6))
   (retract ?check) 
   (assert (winner_is_chosen))
)

(defrule assing_positive_sm
   ?check <- (winner_is_chosen)
   ?sm <- (sm (id ?)(marker ?mark))
   ?win <- (winner (id ?id))
   ?face <- (face (mood ?v ?a))
   (test (> (sqrt (+ (* ?v ?v) (* ?a ?a))) 0.65))
   (test (> ?v 0))
   (test (neq ?mark 1))
   =>
   (modify ?sm (id ?id) (marker 1))
)

(defrule assing_negative_sm
   ?check <- (winner_is_chosen)
   ?sm <- (sm (id ?)(marker ?mark))
   ?win <- (winner (id ?id))
   ?face <- (face (mood ?v ?a))
   (test (> (sqrt (+ (* ?v ?v) (* ?a ?a))) 0.65))
   (test (< ?v 0))
   (test (neq ?mark -1))
   =>
   (modify ?sm (id ?id) (marker -1))
)
   
(defrule MAIN::look_at_winner "Finally, this rule makes the robot look at the winner 
                               making the expression that is the most suitable 
							   to the current social context"
   ?check <- (winner_is_chosen)
   ?face <- (face (ecs ?v ?a) (mood ?mv ?ma))
   ?win <- (winner (id ?id) (point ?x ?y) (lookrule ?rulefired))
   ?sm <- (sm (id ?smid)(marker ?mark))
   (test (and (neq ?id 0) (neq ?rulefired none)))
   =>
   (printout t "  WINNER [" ?id "] - WHY [" ?rulefired "] - ECS (" ?v " | " ?a ") - MOOD (" ?mv " | " ?ma ")      SM -> ID [" ?smid "] - [" ?mark "]"  crlf)
   (fun_lookat ?id ?x ?y)
   (fun_makeexp ?v ?a)
   (modify ?win (id 0) (point 0.0 0.0) (lookrule none))
   (modify ?face (ecs 0.0 0.0))
   (assert (delete subjects))
   (retract ?check)
)


(defrule MAIN::delete_subjects "At the end CLIPS provides to remove all the stored subjects"
   (declare (salience -20))
   (delete subjects)
   ?s <- (subject)
   =>
   (retract ?s)
)


(defrule MAIN::deleting_is_done "Subjects removal is done!"
   ?del <- (delete subjects)
   (not (subject (idKinect ?)))
   =>
   (retract ?del)
   (assert (winner_not_chosen))
)