ifeq ($(TRAVIS),on)
TARGET_TIMER_ID_FILE=/tmp/timer-id-$(shell echo "$(TARGET)" | sed "s/[^[:alpha:]]//g")
TARGET_TIME_FILE=/tmp/time-$(shell echo "$(TARGET)" | sed "s/[^[:alpha:]]//g")
TRAVIS_PRINTABLE_MARKER_NAME=$(shell echo "$(TARGET)" | sed "s/[^[:alpha:]]/-/g")
TARGET_MARKER_START = travis_fold start "$(TRAVIS_PRINTABLE_MARKER_NAME)" && \
	travis_time_start && \
	echo $$travis_timer_id > $(TARGET_TIMER_ID_FILE) && \
	echo $$travis_start_time > $(TARGET_TIME_FILE)
TARGET_MARKER_END = \
	travis_timer_id=$$(cat $(TARGET_TIMER_ID_FILE)) \
	travis_start_time=$$(cat $(TARGET_TIME_FILE)) \
	travis_time_finish && \
	travis_fold end "$(TRAVIS_PRINTABLE_MARKER_NAME)"
else
TARGET_MARKER_START = @echo "starting: $(TARGET)"
TARGET_MARKER_END = @echo "ended $(TARGET)"
endif
