//import AVFoundation
//import Accelerate
//
//class FrequencyMeter {
//    private let engine = AVAudioEngine()
//    private var fftSetup: FFTSetup?
//    private var log2n: vDSP_Length
//    private var n: Int
//    private var window: [Float]
//    private var sampleRate: Double
//    
//    init(fftSize: Int = 4096) throws {
//        // Regras da Sessao de Audio
//        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode: .measurement, options: [.duckOthers])
//        
//        // Ativa a Sessão
//        try AVAudioSession.sharedInstance().setActive(true)
//        
//        // Sample Rate, "FPS"de captura do som
//        sampleRate = AVAudioSession.sharedInstance().sampleRate
//        
//        // FFT Size - quanto maior mais resolução e mais latência
//        n = fftSize
//        
//        // Numero de operações borboleta que o FFT vai rodar = log de 2 n
//        log2n = vDSP_Length(log2(Float(n)))
//        
//        // Define a configuração do FFT, motor do FFT e como vai ser executado
//        
//        //  kFFTRadix2 indica que você quer usar radix-2 FFT, a versão mais eficiente (para tamanhos como 256, 512, 1024, 2048, 4096…).
//        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
//        
//        // Suaviza o som pra não ficar muito despropocional a curva no começo e no fim da onda
//        window = [Float](repeating: 0, count: n)
//        
//        //  preenche o array window com valores da Janela de Hann.
//        // Esse & serve para passar o array por REFERÊNCIA
//        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
//    }
//    
//    
//    // Parâmetro onFrequency é do tipo função, recebe um float retorna void
//    // é uma função a ser executado ao final do codigo (closure)
//    func start(onFrequency: @escaping (Float) -> Void) throws {
//        
//        // entrada do material bruto - som camptado através do microfone (input node) em amplitude
//        let input = engine.inputNode
//        
//        // Verifica o formato do áudio - quantos canais, sample rate, tamanho de frames
//        let format = input.outputFormat(forBus: 0)
//        
//        // FFT Size, quantas amostras são analisadas por vez
//        let frameSize = n
//        
//        // Tap captura pequenos trechos de som repetidamente enquanto o microfone está ativo.
//        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(frameSize), format: format) { [weak self] buffer, _ in
//            guard let self = self else { return }
//            
//            // Pega os valores do audio pelos canais
//            let channelData = buffer.floatChannelData![0]
//            let frameLength = Int(buffer.frameLength)
//            
//            // Copia par um array de sinais preparando para o FFT
//            var signal = [Float](repeating: 0, count: self.n)
//            let copyCount = min(frameLength, self.n)
//            signal.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channelData, count: copyCount))
//            
//            
//            // Aplica a janela de Hann para suavizar os sinais
//            vDSP_vmul(signal, 1, self.window, 1, &signal, 1, vDSP_Length(self.n))
//            
//            var realp = [Float](repeating: 0, count: self.n/2)
//            var imagp = [Float](repeating: 0, count: self.n/2)
//            
//            
//            // Prepara os dados em dyas arrays, uma de Numeros complexos e outra de numeros imaginarios
//            realp.withUnsafeMutableBufferPointer { realPtr in
//                imagp.withUnsafeMutableBufferPointer { imagPtr in
//                    var complexBuffer = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
//                    signal.withUnsafeBufferPointer { signalPtr in
//                        signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: self.n) { complexPtr in
//                            vDSP_ctoz(complexPtr, 2, &complexBuffer, 1, vDSP_Length(self.n/2))
//                        }
//                    }
//                    
//                    
//                    // aplica a FFT, transforma a entrada de amplitude/ volume por domínio de tempo em frequência
//                    
//                    vDSP_fft_zrip(self.fftSetup!, &complexBuffer, 1, self.log2n, FFTDirection(FFT_FORWARD))
//                    
//                    
//                    // Mede a força para encontrar a magnitude das frequencias
//                    var mags = [Float](repeating: 0.0, count: self.n/2)
//                    vDSP_zvabs(&complexBuffer, 1, &mags, 1, vDSP_Length(self.n/2))
//                    
//                    
//                    // Encontra o indice do array com a maior magnitude, a frequencia "dominante"
//                    var maxIndex: vDSP_Length = 0
//                    var maxValue: Float = 0
//                    
//                    mags.withUnsafeBufferPointer { buffer in
//                        let start = buffer.baseAddress! + 1
//                        vDSP_maxvi(start, 1, &maxValue, &maxIndex, vDSP_Length(mags.count - 1))
//                    }
//                    
//                    
//                    // Encontrou o maior valor
//                    let peakIndex = Int(maxIndex) + 1
//                    
//                    
//                    // Interpolação Parabólica de Pico - ajusta o pico de frequencia com seu antecessor e sucessor para encontrar um pico mais regular
//                    let alpha = mags[peakIndex - 1]
//                    let beta  = mags[peakIndex]
//                    let gamma = mags[peakIndex + 1]
//                    let denom = (alpha - 2*beta + gamma)
//                    var p: Float = 0
//                    if denom != 0 {
//                        p = 0.5 * (alpha - gamma) / denom
//                    }
//                    let trueIndex = Float(peakIndex) + p
//                    let frequency = trueIndex * Float(self.sampleRate) / Float(self.n)
//                    
//                    DispatchQueue.main.async {
//                        onFrequency(frequency)
//                    }
//                }
//            }
//        }
//        
//        engine.prepare()
//        try engine.start()
//    }
//    
//    func stop() {
//        engine.inputNode.removeTap(onBus: 0)
//        engine.stop()
//        if let setup = fftSetup {
//            vDSP_destroy_fftsetup(setup)
//        }
//    }
//}


import AVFoundation
import Accelerate

class FrequencyMeter {
    private let engine = AVAudioEngine()
    private var fftSetup: FFTSetup?
    private var log2n: vDSP_Length
    private var n: Int
    private var window: [Float]
    private var sampleRate: Double

    // 🔹 Ajuste a sensibilidade do microfone aqui!
    var thresholdDB: Float = -45.0   // Experimente valores entre -50 e -35

    init(fftSize: Int = 4096) throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)

        sampleRate = AVAudioSession.sharedInstance().sampleRate
        n = fftSize
        log2n = vDSP_Length(log2(Float(n)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
    }

    func start(onFrequency: @escaping (Float) -> Void) throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let frameSize = n

        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(frameSize), format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            // Copia o sinal
            var signal = [Float](repeating: 0, count: self.n)
            let copyCount = min(frameLength, self.n)
            signal.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channelData, count: copyCount))

            // 🔍 CALCULA RMS e Filtro de SENSIBILIDADE
            var rms: Float = 0.0
            vDSP_rmsqv(signal, 1, &rms, vDSP_Length(self.n))
            let db = 20 * log10(rms)
            
            print("DECIVEIS")
            print(db)
            print()
            print()

            // Só continua se houver SOM REAL
            if db < self.thresholdDB || db.isNaN { return }  // <<< Filtro mágico
            
        

            // Aplica Janela de Hann
            vDSP_vmul(signal, 1, self.window, 1, &signal, 1, vDSP_Length(self.n))

            var realp = [Float](repeating: 0, count: self.n/2)
            var imagp = [Float](repeating: 0, count: self.n/2)

            realp.withUnsafeMutableBufferPointer { realPtr in
                imagp.withUnsafeMutableBufferPointer { imagPtr in
                    var complexBuffer = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    signal.withUnsafeBufferPointer { signalPtr in
                        signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: self.n) { complexPtr in
                            vDSP_ctoz(complexPtr, 2, &complexBuffer, 1, vDSP_Length(self.n/2))
                        }
                    }

                    vDSP_fft_zrip(self.fftSetup!, &complexBuffer, 1, self.log2n, FFTDirection(FFT_FORWARD))

                    var mags = [Float](repeating: 0.0, count: self.n/2)
                    vDSP_zvabs(&complexBuffer, 1, &mags, 1, vDSP_Length(self.n/2))

                    var maxIndex: vDSP_Length = 0
                    var maxValue: Float = 0
                    mags.withUnsafeBufferPointer { buffer in
                        let start = buffer.baseAddress! + 1
                        vDSP_maxvi(start, 1, &maxValue, &maxIndex, vDSP_Length(mags.count - 1))
                    }

                    let peakIndex = Int(maxIndex) + 1

                    // Pico parabólico
                    let alpha = mags[peakIndex - 1]
                    let beta  = mags[peakIndex]
                    let gamma = mags[peakIndex + 1]
                    let denom = (alpha - 2*beta + gamma)
                    var p: Float = 0
                    if denom != 0 { p = 0.5 * (alpha - gamma) / denom }

                    let trueIndex = Float(peakIndex) + p
                    let frequency = trueIndex * Float(self.sampleRate) / Float(self.n)

                    DispatchQueue.main.async {
                        onFrequency(frequency)
                    }
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
}
