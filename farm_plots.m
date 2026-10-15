function on = farm_plots(value)
% FARM_PLOTS  Get or set whether the measurement figures are drawn.
%
% farm_plots(false) turns the figures off and farm_plots(true) turns them
% back on; farm_plots() returns the current setting. Figures are on by
% default. Main_FARM sets this from the setup window at the start of every
% run, and each measurement function checks it before plotting.

persistent state
if nargin > 0
    state = logical(value);
end
if isempty(state)
    state = true;
end
on = state;
end
