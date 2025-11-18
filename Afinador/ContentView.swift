//
//  ContentView.swift
//  Afinador
//
//  Created by José Elias Gomes Camargo  on 14/11/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var frequencyText: String = "— Hz"
    @State private var isRunning: Bool = false
    @State private var meter: FrequencyMeter?
    @State private var errorMessage: String?
    @State var frequenciaHz : Double = 440
    @State var nota : String = "A"
    @State var oitava : Int = 4
    @State var classificacaoDaFrequencia = "Agudo"
    @State var estadoDaAfinacao = 1
    @State var afinado = true
    @State var orientacao = "Agudo Demais..."
    @State var diferencaDoCents = 0
    
    let notasFrequencias: [Double: String] = [
        16.35: "C",
        17.32: "C#",
        18.35: "D",
        19.45: "D#",
        20.60: "E",
        21.83: "F",
        23.12: "F#",
        24.50: "G",
        25.96: "G#",
        27.50: "A",
        29.14: "A#",
        30.87: "B"
    ]
    
    
    var body: some View {
        
//        VStack(spacing: 20) {
//            Text(frequencyText)
//                .font(.system(size: 36, weight: .bold))
//                .multilineTextAlignment(.center)
//                .frame(maxWidth: .infinity)
//            
//            HStack(spacing: 16) {
//                Button("Iniciar") { startTapped() }
//                    .buttonStyle(.borderedProminent)
//                    .disabled(isRunning)
//                
//                Button("Parar") { stopTapped() }
//                    .buttonStyle(.bordered)
//                    .disabled(!isRunning)
//            }
//            
//            if let errorMessage {
//                Text(errorMessage)
//                    .font(.footnote)
//                    .foregroundStyle(.red)
//            }
//        }
//        .padding()
//        .onDisappear { stopTapped() }
        
        VStack {
            
            VStack(spacing: 32) {
                
                
                Text("\(frequenciaHz.formatted(.number.locale(.current).precision(.fractionLength(1)))) Hz")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
               
                
                
                
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(nota)
                            .font(.system(size: 84))
                            .fontWeight(.semibold)
                        
                        Text("\(oitava)")
                            .font(.title3)
                    }
                    
                    Text("Som \(classificacaoDaFrequencia)")
                        .font(.title3)
                }
            }
            
            Spacer()
            
            VStack(spacing: 64) {
                
                Group {
                    if estadoDaAfinacao == 0 {
                        Image(systemName: "circle.circle")
                            .resizable()
                            .scaledToFit()
                        
                    } else if estadoDaAfinacao == 1 {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .scaledToFit()
                        
                    } else {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .scaledToFit()
                        
                    }
                }
                .frame(height: 128)
                .symbolEffect(.bounce, options: .speed(0.2).repeat(2), value: afinado)
                
                
                Text(orientacao)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
        }
        .foregroundStyle(.white)
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(estadoDaAfinacao == 0 ? .green : estadoDaAfinacao == 1 ? .red : .orange)
        .onAppear {
//            startTapped()
        }
        .onDisappear {
            stopTapped()
        }
        .onChange(of: frequenciaHz) { oldValue, newValue in
            
            oitava = Int(floor(log2(frequenciaHz / 16.3516)))
            
            var referenciaDistanciaCents = 0
            
            for (frequencia, _) in notasFrequencias {
                
                
                diferencaDoCents = centsDifference(detected: frequenciaHz, target: frequencia * pow(2.0, Double(oitava)))
                
                if diferencaDoCents >= -50 && diferencaDoCents <= 50 {
                    nota = notasFrequencias[frequencia] ?? "Nulo"
                    referenciaDistanciaCents = diferencaDoCents
                }
            }
            
            print(referenciaDistanciaCents)
            
            if referenciaDistanciaCents >= -15 && referenciaDistanciaCents <= 15 {
                estadoDaAfinacao = 0
                orientacao = "Afinado!"
            } else if referenciaDistanciaCents > 15 {
                estadoDaAfinacao = 1
                orientacao = "Agudo Demais"
            } else {
                estadoDaAfinacao = -1
                orientacao = "Grave Demais"
            }

            
            
            
            if frequenciaHz >= 20 && frequenciaHz <= 60 {
                classificacaoDaFrequencia = "Subgrave"
            } else if frequenciaHz >= 61 && frequenciaHz <= 250 {
                classificacaoDaFrequencia = "Grave"
            } else if frequenciaHz >= 251 && frequenciaHz <= 640 {
                classificacaoDaFrequencia = "Médio Grave"
            } else if frequenciaHz >= 641 && frequenciaHz <= 2500 {
                classificacaoDaFrequencia = "Médio"
            } else if frequenciaHz >= 2501 && frequenciaHz <= 5000 {
                classificacaoDaFrequencia = "Médio Agudo"
            } else {
                classificacaoDaFrequencia = "Agudo"
            }
            
            
//            if frequenciaHz.truncatingRemainder(dividingBy: 27.5) < 1 {
//                estadoDaAfinacao = 0
//                orientacao = "Afinado"
//            } else if frequenciaHz < 440 {
//                estadoDaAfinacao = -1
//                orientacao = "Grave Demais"
//                
//            } else {
//                estadoDaAfinacao = 1
//                orientacao = "Agudo Demais"
//            }
            
        }
    }
    
    private func startTapped() {
        do {
            let newMeter = try FrequencyMeter()
            
            // Define a Closure onFrequency (parametor da funcao), pega a frequencia e troca na tela
            try newMeter.start { freq in
                frequencyText = String(format: "%.2f Hz", freq)
                frequenciaHz = Double(freq)
            }
//            meter = newMeter
//            isRunning = true
//            errorMessage = nil
        } catch {
            errorMessage = "Erro ao iniciar: \(error.localizedDescription)"
            isRunning = false
        }
    }
    
    private func stopTapped() {
        meter?.stop()
        meter = nil
        frequencyText = "— Hz"
        isRunning = false
    }
}

#Preview {
    ContentView()
}


func centsDifference(detected: Double, target: Double) -> Int {
    return Int(1200 * log2(detected / target))
}
