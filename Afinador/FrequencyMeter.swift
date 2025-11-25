import AVFoundation
import Accelerate

class FrequencyMeter {
    private let engine = AVAudioEngine()
    private var fftSetup: FFTSetup?
    private var log2n: vDSP_Length
    private var n: Int
    private var window: [Float]
    private var sampleRate: Double

    var thresholdDB: Float = -45.0
    var harmonicCorrectionEnabled: Bool = true  // <-- ATIVA / DESATIVA

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

    func start(onFrequency: @escaping (Float, Float) -> Void) throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(n), format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            var signal = [Float](repeating: 0, count: self.n)
            let copyCount = min(frameLength, self.n)
            signal.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channelData, count: copyCount))

            // 🔍 CALCULA RMS e Filtro de SENSIBILIDADE
            var rms: Float = 0.0
            vDSP_rmsqv(signal, 1, &rms, vDSP_Length(self.n))
            let db = 20 * log10(rms)

            if db < self.thresholdDB || db.isNaN {
                DispatchQueue.main.async { onFrequency(0, 0) }
                return
            }

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

                    // Interpolação Parabólica
                    let alpha = mags[peakIndex - 1]
                    let beta  = mags[peakIndex]
                    let gamma = mags[peakIndex + 1]
                    let denom = (alpha - 2*beta + gamma)
                    var p: Float = 0
                    if denom != 0 { p = 0.5 * (alpha - gamma) / denom }

                    let trueIndex = Float(peakIndex) + p
                    var frequency = trueIndex * Float(self.sampleRate) / Float(self.n)

                    // 🧠 CORREÇÃO AUTOMÁTICA DE HARMÔNICOS
                    if self.harmonicCorrectionEnabled {
                        frequency = self.correctHarmonics(frequency: frequency, mags: mags)
                    }

                    DispatchQueue.main.async {
                        onFrequency(frequency, db)
                    }
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    /// 🔍 Detecta e corrige harmônicos automaticamente
    private func correctHarmonics(frequency: Float, mags: [Float]) -> Float {
        var freq = frequency
        
        // Se estiver acima de 200 Hz, pode ser harmônico
        if freq > 120 && freq < 600 {   // faixa típica onde harmônicos aparecem
                let divCandidates: [Float] = [2, 3]  // dividir por 2 e 3
                
                for div in divCandidates {
                    let candidate = freq / div
                    let bin = Int(candidate * Float(n) / Float(sampleRate))

                    if bin > 1 && bin < mags.count - 1 {
                        let energyCandidate = mags[bin]
                        let energyOriginal = mags[Int(freq * Float(n) / Float(sampleRate))]
                        
                        // Se o candidato tiver energia razoável → usamos ele
                        if energyCandidate > energyOriginal * 0.4 {
                            return candidate  // Encontrou a REAL FUNDAMENTAL! 🎯
                        }
                    }
                }
            }
        
        return freq
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
}
