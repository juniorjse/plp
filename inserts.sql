INSERT INTO Carros (id_carro, marca, modelo, ano, placa, categoria, quilometragem, status, diaria_carro, descricao_carro)
VALUES 
    (1, 'Volkswagen', 'Gol', 2020, 'ABC1234', 'Econômico', 15000, 'D', 100.0, 'Carro compacto ideal para viagens urbanas.'),
    (2, 'Mercedes-Benz', 'Classe C', 2021, 'TUV1234', 'Luxo', 15000, 'O', 300.0, 'Luxuoso e elegante, perfeito para ocasiões especiais.'),
    (3, 'Jeep', 'Compass', 2019, 'EFG1234', 'SUV', 25000, 'O', 200.0, 'Um SUV espaçoso e versátil para aventuras.'),
    (4, 'Ford', 'Ka', 2022, 'JKL2345', 'Econômico', 8000, 'O', 90.0, 'Ótimo consumo de combustível e fácil de manobrar.'),
    (5, 'Renault', 'Kwid', 2021, 'MNO6789', 'Econômico', 12000, 'R', 85.0, 'Compacto e econômico para viagens urbanas.'),
    (6, 'Chevrolet', 'Cruze', 2018, 'PQR1234', 'Intermediário', 40000, 'O', 180.0, 'Um sedan intermediário com conforto e tecnologia.'),
    (7, 'Porsche', '911', 2022, 'EFG6789', 'Esportivo', 12000, 'D', 500.0, 'Um icônico esportivo com desempenho excepcional.'),
    (8, 'Honda', 'Civic', 2019, 'VWX9101', 'Intermediário', 35000, 'D', 170.0, 'Confiável e eficiente, ótimo para viagens.'),
    (9, 'Hyundai', 'HB20S', 2022, 'YZA2345', 'Sedan', 10000, 'D', 150.0, 'Um sedan compacto com visual moderno.'),
    (10, 'Ford', 'Ka Sedan', 2021, 'BCD6789', 'Sedan', 12000, 'D', 95.0, 'Um sedan compacto com espaço interno.'),
    (11, 'Toyota', 'Hilux', 2018, 'QRS2345', 'Pickup', 45000, 'D', 250.0, 'Uma pickup robusta e versátil para cargas.'),
    (12, 'Tesla', 'Model 3', 2022, 'TUV6789', 'Elétrico', 5000, 'D', 350.0, 'Carro elétrico com autonomia avançada.'),
    (13, 'Mini', 'Cooper S', 2021, 'KLM5678', 'Conversível', 35000, 'D', 220.0, 'Um conversível esportivo com estilo único.'),
    (14, 'Audi', 'A4', 2019, 'ZAB9101', 'Luxo', 25000, 'D', 280.0, 'Luxo e desempenho em um pacote elegante.'),
    (15, 'Ferrari', '488 GTB', 2018, 'BCD2345', 'Esportivo', 10000, 'D', 1000.0, 'Um supercarro com potência incomparável.'),
    (16, 'Honda', 'Fit', 2022, 'QRS6789', 'Minivan', 8000, 'D', 120.0, 'Minivan compacta com versatilidade.');

INSERT INTO Usuarios (nome, sobrenome, email, senha, tipo) VALUES ('Mecanico', 'Teste', 'mecanico@gmail.com', '123456789', 'mecanico');
INSERT INTO Usuarios (nome, sobrenome, email, senha, tipo) VALUES ('Administrador', 'Teste', 'admin@gmail.com', '123456789', 'administrador');

INSERT INTO Usuarios (nome, sobrenome, email, senha)
VALUES 
    ('João', 'Silva', 'joao.silva@email.com', 'joao123'),
    ('Maria', 'Santos', 'maria.santos@email.com', 'maria123'),
    ('Pedro', 'Almeida', 'pedro.almeida@email.com', 'pedro123'),
    ('Ana', 'Ferreira', 'ana.ferreira@email.com', 'anaf123'),
    ('Lucas', 'Oliveira', 'lucas.oliveira@email.com', 'lucas123');

INSERT INTO Alugueis (id_carro, id_usuario, data_inicio, data_devolucao, valor_total, status_aluguel)
VALUES 
    (2, 1, '2023-07-05', '2023-07-10', 500.00, 'ativo'),
    (4, 3, '2023-07-03', '2023-07-08', 400.00, 'ativo'),
    (1, 2, '2023-07-06', '2023-07-09', 300.00, 'concluído'),
    (3, 5, '2023-07-04', '2023-07-07', 350.00, 'ativo'),
    (5, 4, '2023-07-07', '2023-07-11', 600.00, 'ativo'),
    (6, 6, '2023-09-20', '2023-09-30', 500.00, 'ativo');

INSERT INTO Locadora (nome, endereco, contato)
VALUES 
    ('Locadora ABC', 'Rua Principal, 123', '+55 (11) 1234-5678'),
    ('Locadora XYZ', 'Avenida Central, 456', '+55 (21) 9876-5432');
