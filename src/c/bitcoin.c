#include <curl/curl.h>
#include <json-c/json.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Struct to hold the fetched data
struct memory {
  char *response;
  size_t size;
};

// Callback function for curl to write response data into memory
static size_t write_callback(void *contents, size_t size, size_t nmemb,
                             void *userp) {
  size_t realsize = size * nmemb;
  struct memory *mem = (struct memory *)userp;

  char *ptr = realloc(mem->response, mem->size + realsize + 1);
  if (ptr == NULL) {
    printf("Not enough memory\n");
    return 0;
  }

  mem->response = ptr;
  memcpy(&(mem->response[mem->size]), contents, realsize);
  mem->size += realsize;
  mem->response[mem->size] = 0;

  return realsize;
}

int main(void) {
  CURL *curl;
  CURLcode res;
  struct memory chunk = {0};

  curl_global_init(CURL_GLOBAL_DEFAULT);
  curl = curl_easy_init();

  if (curl) {
    curl_easy_setopt(curl, CURLOPT_URL,
                     "https://api.coindesk.com/v1/bpi/currentprice/BTC.json");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

    res = curl_easy_perform(curl);

    if (res != CURLE_OK) {
      fprintf(stderr, "curl_easy_perform() failed: %s\n",
              curl_easy_strerror(res));
    } else {
      // Parse the JSON response
      struct json_object *parsed_json;
      struct json_object *bpi;
      struct json_object *usd;
      struct json_object *rate;

      parsed_json = json_tokener_parse(chunk.response);
      json_object_object_get_ex(parsed_json, "bpi", &bpi);
      json_object_object_get_ex(bpi, "USD", &usd);
      json_object_object_get_ex(usd, "rate", &rate);

      printf("Current Bitcoin Price: %s USD\n", json_object_get_string(rate));

      // Free parsed JSON object
      json_object_put(parsed_json);
    }

    // Cleanup curl and free memory
    curl_easy_cleanup(curl);
    free(chunk.response);
  }

  curl_global_cleanup();
  return 0;
}
