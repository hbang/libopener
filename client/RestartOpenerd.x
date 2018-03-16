#include <launch.h>

void (^restartOpenerd)() = ^{
	// ensure we have a fresh start on respring by stopping openerd. handlers *probably* don’t restart
	// openerd themselves, so we kinda need to do it ourselves

	// construct and send the stop job command
	launch_data_t stopJob = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
	launch_data_t jobName = launch_data_new_string("ws.hbang.openerd");
	launch_data_dict_insert(stopJob, jobName, LAUNCH_KEY_STOPJOB);

	launch_data_t stopResult = launch_msg(stopJob);
	launch_data_free(stopJob);

	// get our result, which should be an errno
	if (stopResult && launch_data_get_type(stopResult) == LAUNCH_DATA_ERRNO) {
		int error = launch_data_get_errno(stopResult);

		// 0 seems to indicate no error; EALREADY seems to awkwardly actually mean it wasn’t running
		if (error != 0 && error != EALREADY) {
			HBLogWarn(@"failed to restart openerd — %s", strerror(error));
		}

		launch_data_free(stopResult);
	} else {
		HBLogWarn(@"failed to restart openerd — invalid response from launchd");
	}
};

%ctor {
	if (!IN_SPRINGBOARD) {
		return;
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), restartOpenerd);
}
