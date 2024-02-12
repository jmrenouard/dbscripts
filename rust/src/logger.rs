pub mod logger {
    use fern::colors::{Color, ColoredLevelConfig};
    use std::time::SystemTime;

    pub fn setup_logger() -> Result<(), fern::InitError> {
        // configure colors for the whole line
        let colors = ColoredLevelConfig::new()
            .error(Color::Red)
            .warn(Color::Yellow)
            // we actually don't need to specify the color for debug and info, they are white by default
            .info(Color::Green)
            .debug(Color::White)
            // depending on the terminals color scheme, this is the same as the background color
            .trace(Color::BrightBlack);

        fern::Dispatch::new()
            .chain(std::io::stdout())
            .format(move |out, message, record| {
                out.finish(format_args!(
                    "{} [{}]-{}-{}",
                    humantime::format_rfc3339_seconds(SystemTime::now()),
                    // This will color the log level only, not the whole line. Just a touch.
                    colors.color(record.level()),
                    record.target(),
                    message
                ))
            })
            .apply()?;
        Ok(())
    }
}
