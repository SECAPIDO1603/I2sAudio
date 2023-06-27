#!/usr/bin/env python
# coding: utf-8

# In[2]:


import wave
import numpy as np
from pydub import AudioSegment
#Forzar el audio a una tasa de muestreo de 44100Hz y una profundidad de 16 bits
def convert_wav_to_mono(input_file, output_file, sample_width=2, framerate=12000):
    audio = AudioSegment.from_wav(input_file)
    audio = audio.set_channels(1)
    audio = audio.set_frame_rate(framerate)
    audio = audio.set_sample_width(sample_width)
    audio.export(output_file, format='wav')
    print("Archivo mono guardado:", output_file)

#Convertir el audio mono a txt (hexadecimales en una columna)
def convert_mono_to_txt(input_file, output_file):
    with wave.open(input_file, 'rb') as wav_in:
        sample_width = wav_in.getsampwidth()
        num_frames = wav_in.getnframes()

        # Leer los datos del archivo WAV mono
        audio_data = np.frombuffer(wav_in.readframes(num_frames), dtype=np.int16)
        # Ajustar los valores negativos para tratarlos correctamente en hexadecimal
        adjusted_audio_data = audio_data + abs(np.min(audio_data))
        # Convertir a texto hex en una sola columna
        # [0:16384] al final
        audio_data_hex = [f"{sample:04X}" for sample in adjusted_audio_data]
        # Guardar los datos en un archivo txt
        with open(output_file, 'w') as txt_out:
            txt_out.write('\n'.join(audio_data_hex))
    print("Archivo txt guardado:", output_file)

def convert_txt_to_wav(input_file, output_file, sample_width=2, framerate=12000):
    with open(input_file, 'r') as txt_in:
        # Leer los datos hexadecimales del archivo txt
        audio_data_hex = txt_in.read().splitlines()
        # Convertir de hex a valores enteros
        audio_data = [int(sample_hex, 16) for sample_hex in audio_data_hex]
        # Escribir un nuevo archivo WAV
        with wave.open(output_file, 'wb') as wav_out:
            wav_out.setnchannels(1)
            wav_out.setsampwidth(sample_width)
            wav_out.setframerate(framerate)
            wav_out.writeframes(np.array(audio_data, dtype=np.int16).tobytes())
    print("Archivo WAV guardado:", output_file)

# Declaraicón de entradas y salidas
input_wav = 'audioLoop.wav'
output_mono_wav = 'audio_mono.wav'
output_txt = 'audio.txt'
output_wav = 'audio_reconstructed.wav'

# Convertir a mono
convert_wav_to_mono(input_wav, output_mono_wav)

# Convertir a txt
convert_mono_to_txt(output_mono_wav, output_txt)

# Convertir de txt a WAV
convert_txt_to_wav(output_txt, output_wav)
print('done')


# In[ ]:




