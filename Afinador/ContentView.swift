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
    @State var frequenciaHz : Double = 0
    @State var nota : String = "-"
    @State var oitava : Int = 4
    @State var classificacaoDaFrequencia = "Agudo"
    @State var estadoDaAfinacao = 1
    @State var afinado = true
    @State var orientacao = "Toque para começar..."
    @State var diferencaDoCents = 0
    @State var decibels : Float = -1
    @State var accentColor : Color = .gray
    @State var icon = "music.quarternote.3"
    @State var grayText = false
    @State var playedAtLeastOnce = false
    
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
        //
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
                
                
                HStack(alignment: .bottom) {
                    
                    if playedAtLeastOnce {
                        Text("\(frequenciaHz.formatted(.number.locale(.current).precision(.fractionLength(1)))) Hz")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                    else {
                        Text("- Hz")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }

//                    
//                    Rectangle()
//                        .frame(width: 20, height: CGFloat(decibels != 0 ? decibels / 2 * -1 : 5))
                    
                    
                }
                
                
                
//                Text("\(decibels.formatted(.number.locale(.current).precision(.fractionLength(1)))) dB")
//                    .font(.largeTitle)
//                    .fontWeight(.semibold)
                
                
                
                
                
                
                
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(nota)
                            .font(.system(size: 84))
                            .fontWeight(.semibold)
                        
                        if playedAtLeastOnce {
                            
                            Text("\(oitava)")
                                .font(.title3)
                        }
                    }
                    .foregroundStyle(accentColor)
                    
                    
                    if playedAtLeastOnce {
                        Text("Som \(classificacaoDaFrequencia)")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                        
                    }
                    
                }
                
            }
            
            
            Spacer()
            
            VStack(spacing: 64) {
                
                Group {
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(accentColor)
               
                }
                .frame(height: 128)
                .symbolEffect(.bounce, options: .speed(0.2).repeat(2), value: afinado)
                
                Text(orientacao)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(decibels == 0 ? .gray : .primary)
                
                
            }
            
            Spacer()
            
        }
        
        .padding(32)
        .frame(maxWidth: .infinity)
        
        .onAppear {
            startTapped()
        }
        .onDisappear {
            stopTapped()
        }
        .onChange(of: frequenciaHz) { oldValue, newValue in
            
            
            oitava = Int(round(log2(frequenciaHz / 16.3516)))
            
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
                accentColor = .green
                icon = "circle.circle"
                
            } else if referenciaDistanciaCents > 15 {
                estadoDaAfinacao = 1
                orientacao = "Agudo Demais"
                accentColor = .red
                icon = "arrow.up"
                
                
            } else {
                estadoDaAfinacao = -1
                orientacao = "Grave Demais"
                accentColor = .orange
                icon = "arrow.down"
                
                
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
            try newMeter.start { freq, db in
                if freq != 0 {
                    playedAtLeastOnce = true
                    
                    frequenciaHz = Double(freq)
                    
                    frequencyText = String(format: "%.2f Hz", frequenciaHz.formatted(.number.locale(.current).precision(.fractionLength(1))))
                    
                }
                decibels = db
                
                if decibels == 0 && grayText == false {
                    grayText = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                         
                        withAnimation(.smooth(duration: 1)) {
                            
                            accentColor = .gray
                            grayText = false
                        }
                    }
                    
                }
            }
            meter = newMeter
            isRunning = true
            errorMessage = nil
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
