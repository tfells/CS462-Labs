import requests

url = 'http://localhost:3000/sky/event/cl01x2vsc003jpkxxcw1g20a6/none/sensor/new_sensor'
myobj = {'name': 'testing_1'}

requests.post(url, data = myobj)

url = 'http://localhost:3000/sky/event/cl01x2vsc003jpkxxcw1g20a6/none/sensor/new_sensor'
myobj = {'name': 'testing_2'}

requests.post(url, data = myobj)

url = 'http://localhost:3000/sky/event/cl01x2vsc003jpkxxcw1g20a6/none/sensor/new_sensor'
myobj = {'name': 'testing_3'}

requests.post(url, data = myobj)




url = 'http://localhost:3000/sky/event/cl01x2vsc003jpkxxcw1g20a6/none/sensor/unneeded_sensor'
myobj = {'sensorName': 'testing_2'}

requests.post(url, data = myobj)
