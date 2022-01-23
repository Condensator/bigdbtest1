SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PermissibleCurrencies](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[EntityCountryPermissibleCurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PermissibleCurrencies]  WITH CHECK ADD  CONSTRAINT [EEntityCountryPermissibleCurrency_PermissibleCurrencies] FOREIGN KEY([EntityCountryPermissibleCurrencyId])
REFERENCES [dbo].[EntityCountryPermissibleCurrencies] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PermissibleCurrencies] CHECK CONSTRAINT [EEntityCountryPermissibleCurrency_PermissibleCurrencies]
GO
ALTER TABLE [dbo].[PermissibleCurrencies]  WITH CHECK ADD  CONSTRAINT [EPermissibleCurrency_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[PermissibleCurrencies] CHECK CONSTRAINT [EPermissibleCurrency_Currency]
GO
