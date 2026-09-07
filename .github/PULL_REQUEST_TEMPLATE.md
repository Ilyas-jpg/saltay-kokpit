## Ne değişti · What changed


## Neden · Why
(Olay / ölçüm / kaynak · incident / measurement / source)

## Kontrol listesi · Checklist
- [ ] Script değiştiyse `bash -n` geçti ve sandbox HOME'da test edildi (`HOME=$(mktemp -d) bash scripts/install.sh ...`) · scripts pass `bash -n` and were tested in a sandbox HOME
- [ ] `hooks/vault-index.sh` değiştiyse `bash hooks/vault-index.sh | wc -c` bütçe altında · index still under budget
- [ ] Kişisel veri, müşteri adı, sunucu bilgisi yok · no personal data, client names, server details
- [ ] Davranış çekirdeğine (hafıza protokolü · 5 kural · trafik ışığı) dokunulduysa gerekçe bir olaydır · changes to the behaviour core cite an incident
- [ ] Dokümanlar / CHANGELOG güncellendi · docs / CHANGELOG updated
