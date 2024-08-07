#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void read_cpu_times(unsigned long long int *idle_time,
                    unsigned long long int *total_time) {
  FILE *file = fopen("/proc/stat", "r");
  if (file == NULL) {
    perror("fopen");
    exit(EXIT_FAILURE);
  }

  unsigned long long int user, nice, system, idle, iowait, irq, softirq, steal;

  fscanf(file, "cpu  %llu %llu %llu %llu %llu %llu %llu %llu", &user, &nice,
         &system, &idle, &iowait, &irq, &softirq, &steal);
  fclose(file);

  *idle_time = idle + iowait;
  *total_time = user + nice + system + idle + iowait + irq + softirq + steal;
}

int main() {
  unsigned long long int prev_idle_time, prev_total_time;
  unsigned long long int idle_time, total_time;

  // Read initial CPU times
  read_cpu_times(&prev_idle_time, &prev_total_time);
  sleep(1); // Wait for a second to get a difference

  // Read CPU times again
  read_cpu_times(&idle_time, &total_time);

  // Calculate deltas
  unsigned long long int idle_delta = idle_time - prev_idle_time;
  unsigned long long int total_delta = total_time - prev_total_time;

  // Calculate CPU usage
  double cpu_usage = (1.0 - ((double)idle_delta / (double)total_delta)) * 100.0;

  printf("Current CPU Load: %.2f%%\n", cpu_usage);

  return 0;
}
