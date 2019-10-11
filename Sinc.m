% mySinc(x, a) = sin(2 * pi * a * x) / pi / x
function y = Sinc(x, alpha)
    if x == 0
        y = 2 * alpha;
    else
        y = sin(2 * pi * alpha * x) / pi / x;
    end
end