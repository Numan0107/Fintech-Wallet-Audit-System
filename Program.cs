using Microsoft.Data.SqlClient;
using Dapper;
using System.Data;

var builder = WebApplication.CreateBuilder(args);

var connectionString = "Server=.\\SQLEXPRESS;Database=FintechWalletDB;Trusted_Connection=True;TrustServerCertificate=True;";

var app = builder.Build();

app.MapPost("/api/transfer", async (TransferRequest request) =>
{
    try
    {
        using var connection = new SqlConnection(connectionString);
        var parameters = new DynamicParameters();
        parameters.Add("@SenderWalletId", request.SenderWalletId);
        parameters.Add("@ReceiverWalletId", request.ReceiverWalletId);
        parameters.Add("@Amount", request.Amount);

        await connection.ExecuteAsync(
            "ProcessMoneyTransfer", 
            parameters, 
            commandType: CommandType.StoredProcedure);

        return Results.Ok(new { Status = "Success", Message = "Transfer completed." });
    }
    catch (SqlException ex)
    {
        return Results.BadRequest(new { Status = "Error", ex.Message });
    }
});

app.Run();

public record TransferRequest(Guid SenderWalletId, Guid ReceiverWalletId, decimal Amount);