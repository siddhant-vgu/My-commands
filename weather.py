import urllib.request

print("Fetching live weather info...")
try:

    url = "https://wttr.in"
    req = urllib.request.Request(url, headers={'User-Agent': 'curl'})
    
    with urllib.request.urlopen(req) as response:
        weather_data = response.read().decode('utf-8')
        print("\n" + weather_data.strip() + "\n")
except Exception as e:
    print("Oops! Could not fetch weather right now. Check your internet connection.")