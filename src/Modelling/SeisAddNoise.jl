"""
    SeisAddNoise(d, snr; <keyword arguments>)

Add noise to an N-dimensional input
data `d`. Should specify the signal-to-noise ratio level `snr`.
Noise can be band limited using kewyord `L`.

# Arguments
- `d::Array{Real, N}`: N-dimensional data.
- `snr::Real`: signal-to-noise ratio.
- `db::Bool=false`: Flag is false if snr is given by amplitude. Flag is true if
snr is given in dB.
- `pdf::AbstractString="gaussian"`: random noise probability distribution:
`"gaussian"` or `"uniform"`.
- `L::Int=1`: averaging operator length to band-limit the random noise.

# Examples
```julia
julia> using PyPlot
julia> w = Ricker(); wn = SeisAddNoise(w, 2); plot(w); plot(wn);
MeasureSNR(w, wn)
julia> d = SeisHypEvents(); dn = SeisAddNoise(d, 1.0, db=true, L=9);
SeisPlotTX([d dn]); MeasureSNR(d, dn, db=true)
```
Credits: Juan I. Sabbione, 2016
"""
function SeisAddNoise(d::Array{T, N}, snr::Real; db::Bool=false,
                      pdf::AbstractString="gaussian", L::Int=1) where {T <: Real, N}

    noise = GenNoise(size(d), pdf, L=L)
    if db==false
        noise = noise/norm(noise) * norm(d)/snr
    elseif db==true
        noise = noise/norm(noise) * norm(d)/10.0^(0.05*snr)
    end
    noisy = d + noise
    @assert(abs(MeasureSNR(d, noisy, db=db) - snr) < 1e10*eps(AbstractFloat(snr)))
    return noisy

end

# Generate the noise
function GenNoise(dims::Tuple, pdf::AbstractString; L::Int=1)
    N = length(dims)
    n1 = dims[1]
    N == 1 ? nx = 1 : nx = *(dims[2:end]...)
    hamm = Hamming(L)
    L2 = floor(Int,L/2)
    if pdf=="gaussian"
        noise = randn(n1, nx)
    elseif pdf=="uniform"
        noise = -1 + 2*rand(n1, nx)
    else
        error("pdf must be gussian or uniform")
    end
    for j = 1:nx
         noise[:,j] = conv(noise[:,j], hamm)[L2+1:n1+L2]
    end
    reshape(noise, dims...)
end
