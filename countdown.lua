obs = obslua
src_name = ""
start_h = 0
start_m = 0
cur_text = ""
finish_text = ""

function set_text()
	local time_left = mktime(start_h, start_m)
	local text = ""

	if time_left.h > 0 then
		text = string.format("%01d:%02d:%02d", time_left.h, time_left.m, time_left.s)
	else
		-- We keep the minutes in the countdown just for cleanliness purposes.
		text = string.format("%02d:%02d", time_left.m, time_left.s)
	end

	if time_left.t_s <= 0 then
		text = finish_text
	end
	if text ~= cur_text then
		local src = obs.obs_get_source_by_name(src_name)
		if src ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(src, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(src)
		else
			error("src_name in use is nil. L31")
		end
	end
	cur_text = text
end

function mktime(h, m, s)
	now = os.time()
	start = os.time{hour=h,min=m,sec=s,day=os.date('%d'),month=os.date('%m'),year=os.date('%Y')}
	
	ts = start - now
	hrs = math.floor(ts / 60 / 60)
	min = math.floor(ts / 60 % 60)
	sec = math.floor(ts % 60 % 60)
	return {h=hrs,m=min,s=sec,t_s=ts}
end

function t_callback()
	t = mktime(start_h, start_m, 0)
	if t.t_s < 0 then
		obs.remove_current_callback()
	end
	set_text()
end

--------------------------------------------------------
function script_description()
	return "https://github.com/srfalcon5/obs-countdown"
end
function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "start_h", "Starting Hour", 0, 23, 1)
	obs.obs_properties_add_int(props, "start_m", "Starting minute", 0, 59, 1)
	obs.obs_properties_add_text(props, "finish_text", "Text when timer is over", obs.OBS_TEXT_DEFAULT)
	local p = obs.obs_properties_add_list(props, "source", "Source for countdown clock", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local srcs = obs.obs_enum_sources()
	if srcs ~= nil then
		for _, src in ipairs(srcs) do
			src_id = obs.obs_source_get_unversioned_id(src)
			-- We recognise other source IDs since it's all the same
			if src_id == "text_gdiplus" or src_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(src)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(srcs)
	return props
end
function script_update(settings)
	-- Stop callback timer (should never break)
	obs.timer_remove(t_callback)

	-- Get & set variables
	start_h = obs.obs_data_get_int(settings, "start_h")
	start_m = obs.obs_data_get_int(settings, "start_m")
	src_name = obs.obs_data_get_string(settings, "source")
	finish_text = obs.obs_data_get_string(settings, "finish_text")
	
	-- Make new timer and get restarted
	local src = obs.obs_get_source_by_name(src_name)
	if src ~= nil then
		local active = obs.obs_source_active(src)
		obs.obs_source_release(src)
		set_text()
		obs.timer_add(t_callback, 100)
		print("Updated settings successfully.")
	else
		error("src_name in use is nil. L98")
	end
end
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "start_h", 10)
	obs.obs_data_set_default_int(settings, "start_m", 45)
	obs.obs_data_set_default_string(settings, "finish_text", "Starting Now")
	print("Defaults set from L103:105")
end
function script_load(settings)
	print("Script has loaded *relatively* safely.")
end
