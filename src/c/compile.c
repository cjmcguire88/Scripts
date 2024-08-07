#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define BUFFER_SIZE 4096

char *get_src_dir() {
  static char src_dir[BUFFER_SIZE];
  snprintf(src_dir, sizeof(src_dir), "%s/.build/sources", getenv("HOME"));
  return src_dir;
}

char *get_log_dir() {
  static char log_dir[BUFFER_SIZE];
  snprintf(log_dir, sizeof(log_dir), "%s/.build/log", getenv("HOME"));
  return log_dir;
}

void exoe(const char *message) {
  fprintf(stderr, "\033[1;31m%s: %s\033[0m\n", message, strerror(errno));
  exit(EXIT_FAILURE);
}

int run_command(const char *cmd[]) {
  pid_t pid = fork();
  if (pid == -1) {
    exoe("Error forking process");
  } else if (pid == 0) {
    execvp(cmd[0], (char *const *)cmd);
    exoe("Error executing command");
  }

  int status;
  if (waitpid(pid, &status, 0) == -1) {
    exoe("Error waiting for command");
  }
  return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

void add_key() {
  char compile_error_path[BUFFER_SIZE];
  snprintf(compile_error_path, sizeof(compile_error_path), "%s/compile_error",
           getenv("XDG_RUNTIME_DIR"));

  FILE *compile_error = fopen(compile_error_path, "r");
  if (!compile_error) {
    exoe("Failed to open compile error log");
  }

  char line[BUFFER_SIZE], key[BUFFER_SIZE];
  key[0] = '\0';
  while (fgets(line, sizeof(line), compile_error)) {
    if (strstr(line, "FAILED") && strstr(line, "key")) {
      sscanf(strstr(line, "key") + 4, "%s", key);
      break;
    }
  }
  fclose(compile_error);

  if (strlen(key) > 0) {
    printf("\033[1;34m:: \033[1;37mAdd key: %s?\033[0m\n", key);
    char response = getchar();
    if (response == 'Y' || response == 'y') {
      printf("\033[1;34m:: \033[1;37mAdding key...\033[0m\n");
      const char *cmd[] = {"gpg", "--recv-keys", key, NULL};
      if (run_command(cmd) == 0) {
        return;
      } else {
        printf("\033[1;31m:: \033[1;37mFailed to add key\033[0m\n");
        exit(EXIT_FAILURE);
      }
    } else {
      printf("\033[1;33m:: \033[1;37mSkipping...\033[0m\n");
      exit(EXIT_FAILURE);
    }
  }
}

void comp(int argc, char *argv[]) {
  for (int i = 1; i < argc; ++i) {
    char *pkg = argv[i];
    char src_pkg_dir[BUFFER_SIZE];
    snprintf(src_pkg_dir, sizeof(src_pkg_dir), "%s/%s", get_src_dir(), pkg);

    if (access(src_pkg_dir, F_OK) == 0) {
      const char *rm_cmd[] = {"rm", "-rf", src_pkg_dir, NULL};
      run_command(rm_cmd);
    }

    printf("\033[1;34m:: \033[1;37mDownloading %s PKGBUILD...\033[0m\n", pkg);
    if (chdir(get_src_dir()) != 0) {
      exoe("Missing source directory");
    }

    const char *clone_cmd[] = {"pkgctl", "repo", "clone", pkg, NULL};
    run_command(clone_cmd);

    if (chdir(src_pkg_dir) != 0) {
      exoe("No source directory");
    }

    printf("\n\033[1;34m:: \033[1;37mAttempting compilation\033[0m\n");
    char makepkg_cmd[BUFFER_SIZE];
    snprintf(makepkg_cmd, sizeof(makepkg_cmd),
             "makepkg -Lsi --noconfirm 2>%s/compile_error",
             getenv("XDG_RUNTIME_DIR"));
    const char *compile_cmd[] = {"sh", "-c", makepkg_cmd, NULL};
    if (run_command(compile_cmd) != 0) {
      add_key();
      const char *makepkg_cmd2[] = {"makepkg", "-Li", "--noconfirm", NULL};
      if (run_command(makepkg_cmd2) != 0) {
        printf("\033[1;31mFailed to compile %s\033[0m\n", pkg);
        exit(EXIT_FAILURE);
      }
    }
  }

  printf("\033[1;34m:: \033[1;37mAll packages compiled and installed "
         "successfully\033[0m\n");
}

int main(int argc, char *argv[]) {
  if (geteuid() == 0) {
    exoe("Do not run as root");
  } else {
    struct stat st = {0};
    if (stat(get_src_dir(), &st) == -1) {
      if (mkdir(get_src_dir(), 0700) == -1) {
        exoe("Failed to create source directory");
      }
    }
    comp(argc, argv);
  }

  return 0;
}
