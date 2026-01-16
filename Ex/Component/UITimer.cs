using System;
using System.Collections;
using UnityEngine;
using TMPro;

namespace Ez.UI
{
    public class UITimer : TextMeshProUGUI
    {
        private bool isOn = false; // Whether the timer is running
        private float duration; // Countdown duration in seconds
        private float startTime; // Start time in seconds
        private Coroutine updateCoroutine; // Coroutine for updating the text

        public Action OnStop; // Callback when the timer stops
        
        [NonSerialized]
        public string Prefix = ""; // Prefix text to display before the timer
        
        // Start the countdown with a specified duration
        public void Begin(float countdownDuration)
        {
            duration = countdownDuration;
            startTime = Time.realtimeSinceStartup;
            isOn = true;
            updateCoroutine = StartCoroutine(UpdateTextEverySecond());
        }

        // Pause the countdown
        public void Pause()
        {
            isOn = false;
            if (updateCoroutine != null)
            {
                StopCoroutine(updateCoroutine);
                updateCoroutine = null;
            }
        }

        // Resume the countdown
        public void Resume()
        {
            startTime = Time.realtimeSinceStartup - (duration - GetRemainingTime());
            isOn = true;
            updateCoroutine = StartCoroutine(UpdateTextEverySecond());
        }

        // Stop the countdown and reset the timer
        public void Stop()
        {
            isOn = false;
            if (updateCoroutine != null)
            {
                StopCoroutine(updateCoroutine);
                updateCoroutine = null;
            }
            UpdateText(0);
        }

        private void Update()
        {
            if (isOn)
            {
                float remainingTime = GetRemainingTime();
                if (remainingTime <= 0)
                {
                    remainingTime = 0;
                    isOn = false;
                    if (updateCoroutine != null)
                    {
                        StopCoroutine(updateCoroutine);
                        updateCoroutine = null;
                    }
                    OnStop?.Invoke();
                }
            }
        }

        // Calculate the remaining time based on the start time and duration
        private float GetRemainingTime()
        {
            return duration - (Time.realtimeSinceStartup - startTime);
        }

        private static string ConvertSecondsToTime(float seconds)
        {
            // Convert seconds to TimeSpan
            TimeSpan timeSpan = TimeSpan.FromSeconds(seconds);

            string formattedTime;

            if (timeSpan.Days > 0)
            {
                // Display days and hours
                formattedTime = string.Format("{0}d {1:D2}:{2:D2}:{3:D2}", timeSpan.Days, timeSpan.Hours,
                    timeSpan.Minutes, timeSpan.Seconds);
            }
            else
            {
                // Display only hours
                formattedTime = string.Format("{0:D2}:{1:D2}:{2:D2}", timeSpan.Hours, timeSpan.Minutes,
                    timeSpan.Seconds);
            }

            return formattedTime;
        }

        // Update the displayed text to show the remaining time
        private void UpdateText(float remainingTime)
        {
            if (remainingTime<0)
            {
                remainingTime = 0;

            }
            if (string.IsNullOrEmpty( Prefix))
            {
                text = ConvertSecondsToTime(remainingTime);

            }
            else
            {
                text = string.Format(Prefix, ConvertSecondsToTime(remainingTime));
            }
        }

        // Coroutine to update the text every second
        private IEnumerator UpdateTextEverySecond()
        {
            while (isOn)
            {
                UpdateText(GetRemainingTime());
                yield return new WaitForSeconds(1);
            }
        }
    }
}