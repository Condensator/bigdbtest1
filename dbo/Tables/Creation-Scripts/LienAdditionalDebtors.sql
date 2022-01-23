SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienAdditionalDebtors](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsRemoved] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[LienFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienAdditionalDebtors]  WITH CHECK ADD  CONSTRAINT [ELienAdditionalDebtor_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LienAdditionalDebtors] CHECK CONSTRAINT [ELienAdditionalDebtor_Customer]
GO
ALTER TABLE [dbo].[LienAdditionalDebtors]  WITH CHECK ADD  CONSTRAINT [ELienFiling_LienAdditionalDebtors] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LienAdditionalDebtors] CHECK CONSTRAINT [ELienFiling_LienAdditionalDebtors]
GO
