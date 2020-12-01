package firewall

type Config struct {
	ServerAddress string
	SecureHTTP    bool
}

func NewConfig(serverAddress string) *Config {
	return &Config{
		ServerAddress: serverAddress,
	}
}
