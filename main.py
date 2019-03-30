import os
from flask import Flask
app = Flask(__name__)

printer_name = 'HP_LaserJet_M1005'
file_to_print_path = '/home/pi/file_to_print.pdf'
options_string = '-o fit-to-page -o media=A4'


@app.route("/print")
def print_game():
    print("Got Print request")
    os.system('lprm -P {}'.format(printer_name))
    os.system(
        'lp -d {0} {1} {2}'.format(printer_name, options_string, file_to_print_path))
    return "PRINT OK"


@app.route("/reboot")
def reboot():
    os.system('sudo reboot')
    return "REBOOT OK!"

# @app.route("/add_wifi/<ssid>/<password>")
# def add_wifi_network(ssid,password):
#     os.system('wpa_passphrase {} {} >> /etc/wpa_supplicant/wpa_supplicant.conf'.format(ssid,password))
#     return ('Added new network: {}/{}'.format(ssid,password))


if __name__ == "__main__":
    app.run("0.0.0.0", port=80)
