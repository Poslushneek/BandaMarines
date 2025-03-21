/datum/chem_property/special
	rarity = PROPERTY_DISABLED
	category = PROPERTY_TYPE_ANOMALOUS
	value = 6

/datum/chem_property/special/boosting
	name = PROPERTY_BOOSTING
	code = "BST"
	description = "Повышает эффективность всех других свойств этого химического вещества в организме на 0,5 уровня за каждый уровень этого свойства."
	rarity = PROPERTY_LEGENDARY
	category = PROPERTY_TYPE_METABOLITE

/datum/chem_property/special/boosting/pre_process(mob/living/M)
	return list(REAGENT_BOOST = level * 0.5)

/datum/chem_property/special/hypergenetic
	name = PROPERTY_HYPERGENETIC
	code = "HGN"
	description = "Регенерирует все типы клеточных мембран, устраняя повреждения во всех органах и конечностях."
	rarity = PROPERTY_LEGENDARY
	category = PROPERTY_TYPE_MEDICINE

/datum/chem_property/special/hypergenetic/process(mob/living/M, potency = 1)
	M.heal_limb_damage(potency)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	for(var/datum/internal_organ/O in H.internal_organs)
		M.apply_internal_damage(-potency, O)

/datum/chem_property/special/hypergenetic/process_overdose(mob/living/M, potency = 1, delta_time)
	M.adjustCloneLoss(potency * delta_time)

/datum/chem_property/special/hypergenetic/process_critical(mob/living/M, potency = 1, delta_time)
	M.take_limb_damage(1.5 * potency * delta_time, 1.5 * potency * delta_time)

/datum/chem_property/special/hypergenetic/reaction_mob(mob/M, method=TOUCH, volume, potency)
	if(!isxeno_human(M))
		return
	M.AddComponent(/datum/component/status_effect/healing_reduction, -potency * volume * POTENCY_MULTIPLIER_LOW) //reduces heal reduction if present
	if(ishuman(M)) //heals on contact with humans/xenos
		var/mob/living/carbon/human/H = M
		H.heal_limb_damage(potency * volume * POTENCY_MULTIPLIER_LOW)
	if(isxeno(M)) //more effective on xenos to account for higher HP
		var/mob/living/carbon/xenomorph/X = M
		X.gain_health(potency * volume)

/datum/chem_property/special/organhealing
	name = PROPERTY_ORGAN_HEALING
	code = "OHG"
	description = "Регенерирует все типы клеточных мембран, устраняя повреждения во всех органах."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_MEDICINE

/datum/chem_property/special/organhealing/process(mob/living/M, potency = 1, delta_time)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	for(var/datum/internal_organ/O in H.internal_organs)
		M.apply_internal_damage(-0.5 * potency * delta_time, O)

/datum/chem_property/special/organhealing/process_overdose(mob/living/M, potency = 1)
	M.adjustCloneLoss(POTENCY_MULTIPLIER_MEDIUM * potency)

/datum/chem_property/special/organhealing/process_critical(mob/living/M, potency = 1)
	M.take_limb_damage(POTENCY_MULTIPLIER_HIGH * potency, POTENCY_MULTIPLIER_HIGH * potency)

/datum/chem_property/special/DNA_Disintegrating
	name = PROPERTY_DNA_DISINTEGRATING
	code = "DDI"
	description = "Немедленно разрушает ДНК всех органических клеток, с которыми вступает в контакт. Это свойство высоко ценится WY."
	rarity = PROPERTY_LEGENDARY
	category = PROPERTY_TYPE_TOXICANT|PROPERTY_TYPE_ANOMALOUS
	value = 16

/datum/chem_property/special/DNA_Disintegrating/process(mob/living/M, potency = 1)
	M.adjustCloneLoss(POTENCY_MULTIPLIER_EXTREME * potency)
	if(ishuman(M) && M.cloneloss >= 190)
		var/mob/living/carbon/human/H = M
		H.contract_disease(new /datum/disease/xeno_transformation(0),1) //This is the real reason PMCs are being sent to retrieve it.

/datum/chem_property/special/DNA_Disintegrating/trigger()
	SSticker.mode.get_specific_call(/datum/emergency_call/goon/chem_retrieval, TRUE, FALSE, holder.name) // "Weyland-Yutani Goon (Chemical Investigation Squad)"
	GLOB.chemical_data.update_credits(10)
	message_admins("Исследовательский отдел обнаружил DNA_Disintegrating в [holder.name], тем самым добавляя 10 бонусных технических очков.")
	var/datum/techtree/tree = GET_TREE(TREE_MARINE)
	tree.add_points(10)
	ai_announcement("УВЕДОМЛЕНИЕ: Получена зашифрованная передача данных от ККС \"Ройс\". Шаттл на подходе.")

/datum/chem_property/special/ciphering
	name = PROPERTY_CIPHERING
	code = "CIP"
	description = "Эта чрезвычайно сложная химическая структура представляет собой своего рода биологический шифр."
	rarity = PROPERTY_DISABLED
	category = PROPERTY_TYPE_ANOMALOUS
	value = 16
	max_level = 6

/datum/chem_property/special/ciphering/process(mob/living/M, potency = 1, delta_time)
	if(!GLOB.hive_datum[level]) // This should probably always be valid
		return

	for(var/content in M.contents)
		if(!istype(content, /obj/item/alien_embryo))
			continue
		// level is a number rather than a hivenumber, which are strings
		var/hivenumber = GLOB.hive_datum[level]
		var/datum/hive_status/hive = GLOB.hive_datum[hivenumber]
		var/obj/item/alien_embryo/A = content
		A.hivenumber = hivenumber
		A.faction = hive.internal_faction

/datum/chem_property/special/ciphering/predator
	name = PROPERTY_CIPHERING_PREDATOR
	code = "PCI"
	rarity = PROPERTY_DISABLED // this one should always be disabled, even if ciphering is not
	max_level = 6

/datum/chem_property/special/ciphering/predator/reagent_added(atom/A, datum/reagent/R, amount)
	. = ..()
	var/obj/item/xeno_egg/E = A
	if(!istype(E))
		return

	if(amount < 10)
		return

	if((E.flags_embryo & FLAG_EMBRYO_PREDATOR) && E.hivenumber == GLOB.hive_datum[level])
		return

	E.visible_message(SPAN_DANGER("[capitalize(E.declent_ru(NOMINATIVE))] быстро мутирует."))

	playsound(E, 'sound/effects/attackblob.ogg', 25, TRUE)

	E.hivenumber = GLOB.hive_datum[level]
	set_hive_data(E, GLOB.hive_datum[level])
	E.flags_embryo |= FLAG_EMBRYO_PREDATOR

/datum/chem_property/special/crossmetabolizing
	name = PROPERTY_CROSSMETABOLIZING
	code = "XMB"
	description = "Может метаболизироваться у некоторых видов, кроме человека."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_METABOLITE|PROPERTY_TYPE_ANOMALOUS|PROPERTY_TYPE_CATALYST
	value = 666
	max_level = 2

/datum/chem_property/special/crossmetabolizing/pre_process(mob/living/M)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(H.species.reagent_tag == IS_YAUTJA)
		return list(REAGENT_FORCE = TRUE)
	else if(level < 2)//needs level two to work on humans too
		return list(REAGENT_CANCEL = TRUE)

/datum/chem_property/special/embryonic
	name = PROPERTY_EMBRYONIC
	code = "MYO"
	description = "Химический агент вызывает инфекцию типа ######## паразитарного эмбрионального организма."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_ANOMALOUS
	value = 666

/datum/chem_property/special/embryonic/process(mob/living/M, potency = 1, delta_time)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if((locate(/obj/item/alien_embryo) in H.contents) || (H.species.flags & IS_SYNTHETIC) || !H.huggable) //No effect if already infected
		return
	for(var/i=1,i<=max((level % 100)/10,1),i++)//10's determine number of embryos
		var/obj/item/alien_embryo/embryo = new /obj/item/alien_embryo(H)
		embryo.hivenumber = min(level % 10,5) //1's determine hivenumber
		embryo.faction = FACTION_LIST_XENOMORPH[embryo.hivenumber]

/datum/chem_property/special/transforming
	name = PROPERTY_TRANSFORMING
	code = "HGN"
	description = "Химический агент несет в себе ########, изменяя носителя психологически и физически."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_ANOMALOUS
	value = 666

/datum/chem_property/special/transforming/process(mob/living/M, potency = 1, delta_time)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	H.contract_disease(new /datum/disease/xeno_transformation(0),1)

/datum/chem_property/special/ravening
	name = PROPERTY_RAVENING
	code = "RAV"
	description = "Химический агент несет в себе биологический организм Х-65."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_ANOMALOUS
	value = 666

/datum/chem_property/special/ravening/process(mob/living/M, potency = 1, delta_time)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	H.contract_disease(new /datum/disease/black_goo, 1)

/datum/chem_property/special/curing
	name = PROPERTY_CURING
	code = "CUR"
	description = "Связывается и нейтрализует определенные микробиологические организмы."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_MEDICINE|PROPERTY_TYPE_ANOMALOUS
	value = 666
	max_level = 4

/datum/chem_property/special/curing/process(mob/living/M, potency = 1, delta_time)
	var/datum/species/zombie/zs = GLOB.all_species[SPECIES_ZOMBIE]

	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(H.viruses)
		for(var/datum/disease/D in H.viruses)
			if(potency >= CREATE_MAX_TIER_1)
				D.cure()
				zs.remove_from_revive(H)
			else
				if(D.name == "Unknown Mutagenic Disease" && (potency == 0.5 || potency > 1.5))
					D.cure()
				if(D.name == "Black Goo" && potency >= 1)
					D.cure()
					zs.remove_from_revive(H)

/datum/chem_property/special/omnipotent
	name = PROPERTY_OMNIPOTENT
	code = "OMN"
	description = "Полностью оживляет все функции организма."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_MEDICINE|PROPERTY_TYPE_ANOMALOUS
	value = 666

/datum/chem_property/special/omnipotent/process(mob/living/M, potency = 1, delta_time)
	M.reagents.remove_all_type(/datum/reagent/toxin, 2.5*REM * delta_time, 0, 1)
	M.setCloneLoss(0)
	M.setOxyLoss(0)
	M.heal_limb_damage(POTENCY_MULTIPLIER_VHIGH * potency, POTENCY_MULTIPLIER_VHIGH * potency)
	M.apply_damage(-POTENCY_MULTIPLIER_VHIGH * potency, TOX)
	M.hallucination = 0
	M.setBrainLoss(0)
	M.disabilities = 0
	M.sdisabilities = 0
	M.SetEyeBlur(0)
	M.SetEyeBlind(0)
	M.set_effect(0, WEAKEN)
	M.set_effect(0, STUN)
	M.set_effect(0, PARALYZE)
	M.silent = 0
	M.dizziness = 0
	M.drowsyness = 0
	M.stuttering = 0
	M.confused = 0
	M.sleeping = 0
	M.jitteriness = 0
	for(var/datum/disease/D in M.viruses)
		D.spread = "Remissive"
		D.stage--
		if(D.stage < 1)
			D.cure()
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	for(var/datum/internal_organ/I in H.internal_organs)
		M.apply_internal_damage(-0.5 * potency * delta_time, I)

/datum/chem_property/special/radius
	name = PROPERTY_RADIUS
	code = "RAD"
	description = "Контролирует радиус огня неизвестными способами."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_REACTANT|PROPERTY_TYPE_UNADJUSTABLE
	value = 666

/datum/chem_property/special/radius/reset_reagent()
	holder.chemfiresupp = initial(holder.chemfiresupp)

	holder.rangefire = initial(holder.rangefire)
	holder.radiusmod = initial(holder.radiusmod)
	..()

/datum/chem_property/special/radius/update_reagent()
	holder.chemfiresupp = TRUE

	holder.rangefire = max(holder.rangefire, 0) // Initial starts at -1 for some (aka infinite range), need to reset that to 0 so that calc doesn't fuck up

	holder.rangefire += 1 * level
	holder.radiusmod += 0.1 * level
	..()

/datum/chem_property/special/intensity
	name = PROPERTY_INTENSITY
	code = "INT"
	description = "Контролирует интенсивность огня неизвестными способами."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_REACTANT|PROPERTY_TYPE_UNADJUSTABLE
	value = 666

/datum/chem_property/special/intensity/reset_reagent()
	holder.chemfiresupp = initial(holder.chemfiresupp)

	holder.intensityfire = initial(holder.intensityfire)
	holder.intensitymod = initial(holder.intensitymod)
	..()

/datum/chem_property/special/intensity/update_reagent()
	holder.chemfiresupp = TRUE

	holder.intensityfire += 1 * level
	holder.intensitymod += 0.1 * level
	..()

/datum/chem_property/special/duration
	name = PROPERTY_DURATION
	code = "DUR"
	description = "Контролирует продолжительность пожара неизвестными способами."
	rarity = PROPERTY_ADMIN
	category = PROPERTY_TYPE_REACTANT|PROPERTY_TYPE_UNADJUSTABLE
	value = 666

/datum/chem_property/special/duration/reset_reagent()
	holder.chemfiresupp = initial(holder.chemfiresupp)

	holder.durationfire = initial(holder.durationfire)
	holder.durationmod = initial(holder.durationmod)
	..()

/datum/chem_property/special/duration/update_reagent()
	holder.chemfiresupp = TRUE

	holder.durationfire += 1 * level
	holder.durationmod += 0.1 * level
	..()
